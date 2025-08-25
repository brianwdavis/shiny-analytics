source("secrets.R")
bootswatch = "flatly"

make_connection = function(creds) {
  DBI::dbConnect(
    RPostgres::Postgres(),
    user = creds$user,
    password = creds$password,
    host = creds$host,
    dbname = creds$dbname,
    sslmode = "require",
    bigint = "numeric"
  )
}