#cargamos las dependencias
library(STRINGdb)
library(dplyr)
library(ggplot2)
library(readr)


crea_stringdb = function(organism, threshold=400){
  # Función para crear el objeto de string database que usaremos para las consultas
  # @param organism     Número entero que determina el organismo para el que se harán las consultas. Homo sapiens es 9606
  # @param threshold    Valor entero que determina el score mínimo de una interacción para ser considerada
  # @return             Devuelve un objeto de tipo STRINGdb
  
  #creamos la base de datos
  string_db = STRINGdb$new(version="12.0",
                           species=organism,
                           score_threshold=threshold #cualquier interacción con score inferior a este no será considerada
  )
  return(string_db)
}

get_interacciones = function(genes, database, filename, organism, path_database="data/"){
  # Para una lista de genes, busca las interacciones en la base de datos pasada como parámetro y devuelve un data.frame con el número de interacciones por gen
  # @param genes        Lista de genes del fichero
  # @param database     Objeto de tipo STRINGdb sobre el que hacer las consultas
  # @param filename     Cadena de texto que tiene el nombre del fichero (si se han introducido pegándolos será List1, List2...)
  # @param organism     Número entero que determina el organismo para el que se harán las consultas. Homo sapiens es 9606
  # @return conteos     Devuelve un data.frame con las columnas Gene y Freq, correspondiéndose con el número de interacciones por gen
  
  #los mapeamos a proteínas (obtenemos el identificador STRING correspondiente a cada Gene Symbol) mediante consulta de la base de datos estática descargada
  symbol2string = read.delim(paste0(path_database,organism,".txt"),sep="\t")
  symbol2string = symbol2string[,1:2]
  colnames(symbol2string) = c("STRING_id","gene_names")
  mapped_proteins = symbol2string %>%
    filter(gene_names %in% genes)%>%
    select(gene_names, STRING_id)
  #obtenemos las interacciones entre proteínas y sustituimos los STRING_id por Gene Symbol
  interactions = unique(database$get_interactions(mapped_proteins$STRING_id))%>%
    merge(
      mapped_proteins[, c("STRING_id", "gene_names")],
      by.x = "from",
      by.y = "STRING_id",
      all.x = TRUE
    ) %>%
    mutate(from = gene_names) %>%
    mutate(gene_names = NULL) %>%
    merge(
      mapped_proteins[, c("STRING_id", "gene_names")],
      by.x = "to",
      by.y = "STRING_id",
      all.x = TRUE
    ) %>%
    mutate(to = gene_names) %>%
    mutate(gene_names = NULL)
  
  #obtenemos el número de enlaces de cada gen/proteína
  #primero los enlaces en los que la proteína es origen
  conteos_from = data.frame(table(interactions$from))
  #luego los enlaces en que es destino
  conteos_to = data.frame(table(interactions$to))
  #unimos ambos dataframes sumando las frecuencias
  conteos = full_join(conteos_from, conteos_to, by = "Var1", suffix = c("_from", "_to")) %>%
    # Reemplazar valores NA con 0 para poder sumar
    mutate(Freq_from = ifelse(is.na(Freq_from), 0, Freq_from),
           Freq_to = ifelse(is.na(Freq_to), 0, Freq_to)) %>%
    # Crear la columna Freq con la suma
    mutate(Freq = Freq_from + Freq_to) %>%
    # Seleccionar solo las columnas relevantes
    select(Var1, Freq)
  
  colnames(conteos) = c("Gene","Freq")
  
  #incluimos una columna con el nombre del fichero explorado
  conteos$File = filename
  
  #devolvemos el data.frame conteos
  return(conteos)
}

get_n_ids = function(genes, all_data, filename){
  # Para un fichero dado calcula cuántos identificadores se proporcionaron y cuántos forman parte de alguna red
  # @param genes        Lista de identificadores iniciales 
  # @param all_data     Data.frame que contiene la relación entre ID-apariciones-fichero
  # @param filename     Debe ser el nombre del archivo que se desea analizar
  # @return df          Data.frame con el número de ID proporcionados en un fichero (Initial_IDs) y el número que forman parte de la red (Net_IDs)
  
  #contamos los genes iniciales del fichero
  n_initial = length(genes)
  #contamos los genes asignados a la red
  n_net = nrow(all_data[all_data$File == filename,])
  df = data.frame(File=filename, Initial_IDs = n_initial, Net_IDs = n_net)
  return(df)
}

modifica_html = function(proteins,organism,path){
  # Modifica el archivo html que permite la creación de la red de interacción entre proteínas
  # @param proteinas    Lista de identificadores que cumplen los requisitos
  # @param organism     Número entero que determina el organismo para el que se harán las consultas. Homo sapiens es 9606  
  # @param path         Ruta en la que se encuentra el fichero html a modificar
  # @return             No devuelve ningún elemento
  # Leer el contenido del archivo HTML
  html_content <- readLines(path)
  
  # Reemplazar el valor de species y proteins
  html_content <- gsub('species: "9606"', paste0('species: "', organism, '"'), html_content)
  html_content <- gsub('var proteins = \\[.*?\\];', paste0('var proteins = ["', paste(unlist(proteins), collapse = '", "'), '"];'), html_content)
  
  # Guardar el HTML modificado en un nuevo archivo
  writeLines(html_content, path)
}