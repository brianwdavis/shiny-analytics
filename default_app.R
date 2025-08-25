library(shiny.telemetry)
analytics_app(
  data_storage = DataStoragePostgreSQL$new(
    username = dstadmin_creds$user,
    password = dstadmin_creds$password,
    hostname = dstadmin_creds$host,
    port = as.integer(dstadmin_creds$port),
    dbname = dstadmin_creds$dbname,
    driver = "RPostgres"
  )
)
