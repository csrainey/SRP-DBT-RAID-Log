#!/usr/bin/env bash
#----------------------------------------------------------------------
# Script to download a dbt model from github, and deploy to the server
# This can be used for the test deploy as well as the production deployment
# 
# Original goal of the scrip was to be used as a step in an AzureML pipeline
# 
# Cameron Rainey <csrainey@energetics.com>
# Last updated 2022-10-14
#----------------------------------------------------------------------

set -e 
DEFAULT_TARGET='test'
TMP_DIR=$(mktemp -d)



if [ "$1" = "" ]; then

echo "No target provided, defaulting to $DEFAULT_TARGET"
TARGET=$DEFAULT_TARGET
else
TARGET=$1
fi

echo "dbt Target: $TARGET"
echo 'Using Temp Dir: ' $TMP_DIR


# Retreive the private dbt SSH deploy keys
echo "Retreiving Deploy Key Secret"

python get_key.py --keyname dbtSRPDeployKeyPrivate >> $TMP_DIR/id_rsa
python get_key.py --keyname dbtSRPDeployKeyPublic >> $TMP_DIR/id_rsa.pub

# Change the permissions on the private key (probably redundent since in user only accessable temp folder)
chmod 600 $TMP_DIR/id_rsa

# pull the git repo
git clone git@github.com:Energetics-STAR/SRP-DBT.git $TMP_DIR/repo  --config core.sshCommand="ssh -i $TMP_DIR/id_rsa -o StrictHostKeyChecking=no "
echo "SUCCESS"

echo "Clean up the key"
rm   $TMP_DIR/id_rsa*


echo "Setting the Secrets as ENVs"
export DBT_SQL_SECRET=$(python3 $TMP_DIR/repo/get_key.py )


echo "Beginning Deployment to target: $TARGET"
DBT_PROJECT_DIR=$TMP_DIR/repo/srp
DBT_PROFILES_DIR=$TMP_DIR/repo/.dbt

dbt deps --project-dir $DBT_PROJECT_DIR --profiles-dir $DBT_PROFILES_DIR 

# --- run the deployment ---

# Would use 'dbt build' here, but there is currently an issue with dbt 
# and sqlserver when running tests using more than one thread
# https://github.com/dbt-msft/dbt-sqlserver/issues/195
# 
# Once this issue is resolved, we can switch this back to a single 'dbt build' 
# call
dbt seed --project-dir $DBT_PROJECT_DIR --target $TARGET --profiles-dir $DBT_PROFILES_DIR --full-refresh
dbt snapshot --project-dir $DBT_PROJECT_DIR --target $TARGET --profiles-dir $DBT_PROFILES_DIR 
dbt run --project-dir $DBT_PROJECT_DIR --target $TARGET --profiles-dir $DBT_PROFILES_DIR --full-refresh
dbt test --project-dir $DBT_PROJECT_DIR --target $TARGET --profiles-dir $DBT_PROFILES_DIR --threads 1

# Cleanup the Temp Folder
rm -fR $TMP_DIR
