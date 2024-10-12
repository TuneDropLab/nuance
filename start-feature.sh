   #!/bin/bash

   # Usage: ./start-feature.sh feature-name

   if [ -z "$1" ]; then
     echo "Usage: $0 feature-name"
     exit 1
   fi

   FEATURE_NAME=$1

   git flow feature start "$FEATURE_NAME"
