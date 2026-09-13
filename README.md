# sos-state-tx-elections

Use Cursor Agents/Project to build a precinct-level database of Texas historical primary and general returns, likely from data stored via https://www.sos.state.tx.us/elections/index.shtml.  Think about it like a database: We want a precinct table, a candidate metadata table, a votes (at precinct level) table, etc. 

Use R, tidyverse, parquet, where possible. 

Use the candidate and district/ variable naming format in CAGE (https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/DGDRDT). Validate general election totals against the CAGE dataset too.

Do not git track large datasets. Only keep reproducible splits.

Try to set up functions like a standard R package format (https://r-pkgs.org/) with roxygen

