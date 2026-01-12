# Force Homebrew paths for xml2
if ("xml2" %in% old.packages(repos = "https://cloud.r-project.org")[, "Package"]) {
  install.packages("xml2",
    configure.vars = "INCLUDE_DIR=/opt/homebrew/opt/libxml2/include LIB_DIR=/opt/homebrew/opt/libxml2/lib",
    repos = "https://cloud.r-project.org",
    type = "source"
  )
}

# Update the rest
update.packages(ask = FALSE, repos = "https://cloud.r-project.org")
