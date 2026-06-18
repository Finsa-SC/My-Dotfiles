#!/bin/bash

NAMEFILE=$1
CURRENT_DIR=$(pwd)

if [[ -z "$NAMEFILE" ]]; then
  echo "Please input file name first"
  exit 1
else
  if [[ "$NAMEFILE" != *.sh ]]; then
    FINALNAME="$NAMEFILE.sh"
  else
    FINALNAME="$NAMEFILE"
  fi
  
  echo "#!/bin/bash" > "$FINALNAME"
  chmod +x "$FINALNAME"
  echo "Creating script completed!"
  echo "Saved as $CURRENT_DIR/$FINALNAME"

fi
