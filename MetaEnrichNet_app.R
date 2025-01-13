#importamos los paquetes necesarios
library(shiny)
library(shinyjs)
library(bslib)
library(dplyr)
library(DT)
library(ggplot2)
library(shinycssloaders)
library(shinyWidgets)
library(shinyBS)

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# UI ----
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

#definimos la interfaz de usuario
ui = page_sidebar(
  useShinyjs(),
  # título de la app
  title = "MetaEnrichNet",
  
  #creamos una barra lateral 
  sidebar = sidebar(
    #con un ancho de 300px
    width = "300px",
    
    
    #creamos una pestaña en la barra lateral
    tabsetPanel(
      
      # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
      ## ANALYSIS ----
      # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
      tabPanel("Analysis", #el título de la pestaña será Analysis
               #creamos una opción de selección única para escoger la modalidad de introducción de los datos
               tooltip(
                 radioButtons(inputId = "inputMethod",
                            label = "Input Method",
                            choices = c("Upload Files" = "files",
                                        "Paste Genes" = "paste"),
                            selected = "files"),
                 "You can enter data by uploading .txt files or by pasting lists of identifiers.",
                 id = "input", 
                 placement = "right"
                 ),
               
               #pueden introducirse desde el explorador de archivos
               conditionalPanel(
                 condition = "input.inputMethod == 'files'",
                 fileInput(inputId = "files",
                           label = "Choose txt Files",
                           multiple = TRUE,
                           accept = ".txt"),
               ),
               
               #o pueden usarse los datos de ejemplo incluidos en el material entregado
               HTML("Use example data?"),
               tooltip(
               switchInput(inputId = "useExampleData",
                           onLabel = "Yes",
                           offLabel = "No",
                           value = FALSE),
               "Check to use an example dataset consisting of 4 files with identifiers of proteins overexpressed in hepatocarcinoma.",
               id = "exdata", 
               placement = "right"
               ),
               
               #o pueden introducirse pegando los IDs separando listas con ###
               conditionalPanel(
                 condition = "input.inputMethod == 'paste'",
                 tooltip(
                   textAreaInput(inputId = "pastedGenes",
                                 label = "Paste Gene Lists",
                                 placeholder = "GeneX1\nGeneX2\n###\nGeneY1\nGeneY2\n...",
                                 height = "160px"),
                   "Paste the proteins list using ### as separator between lists.",
                   id = "paste", 
                   placement = "right"
                 )
               ),
               
               #con un desplegable escogemos el organismo al que corresponden los genes/proteínas
               tooltip(
                 selectInput(inputId = "organism",
                           label = "Organism",
                           choices = c("Homo sapiens" = 9606,
                                       "Mus musculus" = 10090,
                                       "Escherichia coli K-12" = 511145),
                           selected = 9606),
                 "Organism to which your identifiers belong.",
                 id = "org", 
                 placement = "right"
               ),
               
               #establecemos el valor mínimo de Score para considerar las interacciones entre proteínas
               tooltip(
                 numericInput(inputId = "threshold",
                              label = "Threshold value:",
                              value = 400, min = 0, max = 1000),
                 "Minimum evidence score for a protein-protein interaction to be considered in the STRING model. Higher Threshold values will be more restrictive and imply a lower number of interactions considered.",
                 id = "th",
                 placement = "right"
               ),
               
               #establecemos el número de redes mínimo en que debe aparecer una proteína para ser incluida en el grafo
               tooltip(
                 numericInput(inputId = "minNets",
                              label = "Min. number of nets for including a protein:",
                              value = 2, min = 1),
                 "Minimum number of networks in which a protein must be involved to be included in the total network. Caution, if you enter a value that is too restrictive you may not get any result in the network.",
                 id = "nets",
                 placement = "right"
               ),
               
               #y establecemos el número de interacciones medias mínimo que debe tener una proteína para ser incluida en el grafo
               tooltip(
               numericInput(inputId = "minMean",
                            label = "Min. Mean Interactions for including a protein:",
                            value = 25, min = 0),
                 "Minimum number of average interactions per network that a protein must have to be included in the total network. Caution, if you enter a value that is too restrictive you may not get any result in the network.",
                 id = "mean",
                 placement = "right"
               ),
               
               #finalmente incluimos un botón para la ejecución del análisis
               actionButton(inputId = "runButton",
                            label = "Run Analysis")
      ), #end tabpanel Analysis
      
      # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
      ## DOWNLOADS ----
      # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
      
      #creamos otra pestaña en la barra lateral, para la descarga de archivos
      tabPanel("Downloads", #el título de la pestaña será Downloads
               #con un desplegable escogemos el formato para el data.frame de número de interacciones
               selectInput(inputId = "formatInteractions",
                           label = "Interactions per ID Format",
                           choices = c("TSV" = ".tsv",
                                       "CSV" = ".csv",
                                       "TXT" = ".txt"),
                           selected = "tsv"),
               
               #incluimos el botón para descargarlo
               downloadButton(outputId = "downInteractions",
                              label = "Interactions"),
               
               #con un desplegable escogemos el formato para el data.frame de número de proteínas involucradas en la red por fichero
               selectInput(inputId = "formatIds",
                           label = "IDs Involved per File Format",
                           choices = c("TSV" = ".tsv",
                                       "CSV" = ".csv",
                                       "TXT" = ".txt"),
                           selected = "tsv"),
               
               #incluimos el botón para descargarlo
               downloadButton(outputId = "downIds",
                              label = "IDs"),
               
               # finalmente incluimos el botón para descargar el HTML con la red total de proteínas consideradas
               tags$p("Download HTML Protein Network"),
               downloadButton(outputId = "downNetwork",
                              label = "Network")
               
      ) #end tabpanel
    ) #end tabset panel
  ), #end sidebar

  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  ## CARDS ----
  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  
  #aquí es donde mostrará la salida de nuestro programa
  card(
    tabsetPanel(
      id = "mainTabs",
      #creamos una primera ventana de bienvenida donde se muestra la descripción del programa
      tabPanel("Welcome", 
               tags$div(
                 style = "display: flex; flex-direction: column; justify-content: center; align-items: center; height: 100%; text-align: justify; margin-top: 5%; margin-left: 5%; margin-right: 5%;",
                 h2("Welcome to MetaEnrichNet"),
                 hr(),
                 p("MetaEnrichNet is a web-based tool designed for the analysis of protein-protein interactions between IDs obtained as a result of different tests. The goal is to easily integrate the information generated in different studies to find those proteins (or genes) with the highest relevance."),
                 p("For each list of proteins entered, the interactions will be analysed, obtaining a final count of the average number of interactions identified for each protein, as well as the number of networks of which it is a part.In addition, the number of proteins that make up an interaction network among all those entered for each list of proteins will be shown, and the interaction network between all of them will be displayed."),
               )
      ),
      
      #incluimos la ventana para mostrar el data.frame con el número de interacciones por proteína
      tabPanel("Interactions per ID", DT::dataTableOutput("interactionsTable")),
      
      #la ventana con el data.frame con el número de proteínas involucradas por fichero
      tabPanel("IDs Involved per File", DT::dataTableOutput("idsTable")),
      
      #finalmente incluimos la ventana para mostrar la red de interacciones entre proteínas
      tabPanel("Network Plot",
               tooltip(
                 #incluimos un botón para actualizar el contenido de la red de interacciones
                 actionButton(inputId = "updateNet",
                              label = "Update Network",
                              class = "btn-sm"),
                 "Update the appearance of the network considering the Min. Nets and Min. Mean Interactions filters.",
                 id = "update", 
                 placement = "right"
               ),
               htmlOutput("htmlContent"))
    )
  ) #end card
  
) #end ui


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# SERVER ----
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

# Definimos el funcionamiento de la web
server <- function(input, output, session) {
  
  #cargamos las funciones del archivo que vamos a emplear
  source("./R/MetaEnrichNet_functions.R")
  
  #definimos los archivos de ejemplo
  exampleFiles <- c("data/GSE10072.LCvsNormal.txt",
                    "data/GSE19188.LCvsNormal.txt",
                    "data/GSE63459.LCvsNormal.txt",
                    "data/GSE75037.LCvsNormal.txt")
  
  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  ## EJECUCIÓN ANÁLISIS ----
  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  
  # AL PULSAR EL BOTÓN DE RUN ANALYSIS SE EJECUTA EL CÓDIGO, hasta que no se pulsa no se ejecuta
  observeEvent(input$runButton, {
    #incluimos la cláusula withProgress para mostrar al usuario el avance del programa
    withProgress(
      message = 'Analysis in progress',
      value=0,
      {
      
        incProgress(0.1, detail = "Loading files...")
        #cargamos las listas de genes/proteínas introducidas
        geneLists <- reactive({
          #fundamental comprobar que se haya indicado algún método de input
          req(input$inputMethod)
          
          #si se ha indicado el uso de los datos de ejemplo
          if (input$useExampleData) {
            #se definen los nombres de los ficheros de ejemplo
            list_ids = c("GSE10072.LCvsNormal.txt","GSE19188.LCvsNormal.txt","GSE63459.LCvsNormal.txt","GSE75037.LCvsNormal.txt")
            #leemos las líneas del fichero
            gene_data = lapply(exampleFiles, function(file){
              genes = readLines(file)
              return(unique(genes))
            }) #end lapply
            return(list(ids = list_ids, data = gene_data))
          }
          
          #inicializamos la lista de nombres de ficheros vacía
          list_ids = NULL
          
          #si el método de input es "files" leemos los ficheros introducidos
          if (input$inputMethod == "files"){
            #imprescindible que haya ficheros
            req(input$files)
            
            #la lista de ids será la lista de nombre de los ficheros
            list_ids = input$files$name
            
            #leemos las líneas de los ficheros
            gene_data = lapply(input$files$datapath, function(file){
              genes = readLines(file)
              return(unique(genes))
            }) #end lapply
            return(list(ids = list_ids, data = gene_data))
          #si el método es "paste", separamos las cadenas introducidas por ###
          } else if (input$inputMethod == "paste"){
            #imprescindible que se haya introducido algún texto como input
            req(input$pastedGenes)
            
            rawText = input$pastedGenes
            
            #extraemos las listas de genes
            lists = strsplit(rawText, split = "###\n")[[1]]
            #asignamos un nombre a cada lista
            list_ids = paste0("List", seq_along(lists))
            
            gene_data = lapply(lists, function(list){
              genes = strsplit(list, split = "\\s+")[[1]]
              return(unique(genes))
            }) #end lapply
            return(list(ids = list_ids, data = gene_data))
          } #end ifelse
        }) #end geneLists
        
        incProgress(0.3, detail = "Creatin STRING model...")
        #creamos el objeto de STRING para el organismo deseado
        string_db <- reactive({
          # Crea el objeto string_db
          crea_stringdb(as.integer(input$organism), input$threshold)
        })
        
        incProgress(0.5, detail = "Getting protein-protein interactions...")
        #creamos el data.frame de interactions
        interactions_df <- reactive({
          req(geneLists(), string_db())
          
          #obtener listas de genes y nombres de archivos
          gene_lists = geneLists()$data
          list_ids = geneLists()$ids
          string_db = string_db()
          
          # Crear el dataframe vacío para almacenar resultados
          interactions = data.frame(
            Gene = character(),
            Freq = numeric(),
            File = character()
          )
          
          # Iterar sobre las listas de genes y nombres
          for (i in seq_along(gene_lists)) {
            genes = gene_lists[[i]]
            filename = list_ids[i]
            
            # Obtener las interacciones para la lista actual
            interactions_current = get_interacciones(genes, string_db, filename, input$organism)
            
            # Añadir al dataframe de interacciones
            interactions = rbind(interactions, interactions_current)
          }
          
          return(interactions)
        })
        
        
        incProgress(0.65, detail = "Calculating interactions per protein...")
        #creamos el data.frame con el número medio de interacciones por proteína 
        results_df <- reactive({
          req(interactions_df())
          
          #para cada proteína/gen agrupamos sus interacciones por red y calculamos la media
          results = interactions_df() %>%
            group_by(Gene) %>%
            summarize(
              Nets = n(),
              Mean_Interactions = round(mean(Freq),2)
            )
          return(results)
        })
        
        incProgress(0.8, detail = "Calculating proteins per file...")
        #obtenemos el data.frame con el número de proteínas involucradas en la red por cada lista/archivo de proteínas
        ids_df <- reactive({
          req(geneLists(), string_db())
          
          #obtenemos listas de genes y nombres de archivos
          gene_lists = geneLists()$data
          list_ids = geneLists()$ids
          
          #creamos el dataframe vacío para almacenar resultados
          ids = data.frame(
            File = character(),
            Initial_IDs = numeric(), #número de genes/proteínas de partida
            Net_IDs = numeric() #número de proteínas involucradas en la red
          )
          
          #iteramos sobre las listas de genes y nombres
          for (i in seq_along(gene_lists)) {
            genes = gene_lists[[i]]
            filename = list_ids[i]
            
            #obtenemos las interacciones para la lista actual
            ids_current = get_n_ids(genes, interactions_df(), filename)
            
            #añadimos al dataframe de interacciones
            ids = rbind(ids, ids_current)
          }
          
          return(ids)
        })
        
        incProgress(0.95, detail = "Updating network HTML...")
        #modificamos el archivo de network.html empleado para la representación de la red total de proteínas
        observe({
          req(results_df())
          #obtenemos la lista de proteínas que cumplen los requisitos de número de redes y número de interacciones
          proteinas = results_df() %>%
            filter(Nets >= input$minNets, Mean_Interactions >= input$minMean) %>%
            select(Gene)
          #actualizamos el html
          modifica_html(proteinas,input$organism,"network.html")
        })
      
        # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
        ## RESULTADOS ----
        # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  
        #representamos el data.frame de interacciones en la ventana interactionsTable
        output$interactionsTable <- DT::renderDataTable({
          req(results_df()) # Asegúrate de que interactions no sea NULL
          DT::datatable(results_df(), options = list(pageLength = 10))
        })
        
        #representamos el data.frame de proteínas por fichero en la ventana idsTable
        output$idsTable <- DT::renderDataTable({
          req(ids_df()) # Asegúrate de que interactions no sea NULL
          DT::datatable(ids_df(), options = list(pageLength = 10))
        })
        
        #representamos el HTML con la red de proteínas en la ventana htmlContent
        output$htmlContent <- renderUI({
          req(results_df()) # Asegúrate de que interactions no sea NULL
          includeHTML("network.html")
        })
        
        
        # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
        ## DESCARGAS DE FICHEROS ----
        # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
        
        output$downInteractions <- downloadHandler(filename = function() {
          formato = input$formatInteractions
          paste("Interactions_per_gene_", Sys.Date(), formato)
          },
          content = function(file) {
            formato = input$formatInteractions
            if(formato == ".tsv"){
              write.table(results_df(), file, sep = "\t", col.names = TRUE, row.names = FALSE)
            } else if(formato == ".csv"){
              write.csv(results_df(), file, col.names = TRUE, row.names = FALSE)
            } else {
              write.table(results_df(), sep = " ", file, col.names = TRUE, row.names = FALSE)
            }
          }
        )
        
        output$downIds <- downloadHandler(filename = function() {
          formato = input$formatIds
          paste("IDs_per_file", Sys.Date(), formato)
          },
          
          content = function(file) {
            formato = input$formatIds
            if(formato == ".tsv"){
              write.table(ids_df(), file, sep = "\t", col.names = TRUE, row.names = FALSE)
            } else if(formato == ".csv"){
              write.csv(ids_df(), file, col.names = TRUE, row.names = FALSE)
            } else {
              write.table(ids_df(), sep = " ", file, col.names = TRUE, row.names = FALSE)
            }
            
          }
        )
        
        output$downNetwork <- downloadHandler(
          filename = function() {
            paste("Proteins_network", Sys.Date(), ".html")  # Nombre del archivo descargado
          },
          content = function(file) {
            html_content <- readLines("network.html")
            writeLines(html_content,file)
          })
        
        # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
        ## ACTUALIZACIÓN HTML ----
        # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
        
        #al pulsar el botón de update Network se actualiza el HTML para evitar tener que volver a ejecutar el análisis
        observeEvent(input$updateNet,{
          #modificamos el archivo de network.html
          observe({
            req(results_df())
            proteinas = results_df() %>%
              filter(Nets >= input$minNets, Mean_Interactions >= input$minMean) %>%
              select(Gene)
            modifica_html(proteinas,input$organism,"network.html")
          })
          
          #mostramos el nuevo HTML 
          output$htmlContent <- renderUI({
            req(results_df()) # Asegúrate de que interactions no sea NULL
            includeHTML("network.html")
          })
          
          #cambiamos la ventana a Network Plot
          updateTabsetPanel(session, inputId = "mainTabs", selected = "Network Plot")
        })
  
      }
    )
    #cambiamos la ventana tras Run Analysis a Interactions per ID
    updateTabsetPanel(session, inputId = "mainTabs", selected = "Interactions per ID")
  })
  
}#end server

#por último hay que ejecutar la aplicación 
shinyApp(ui = ui, server = server)