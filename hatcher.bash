#!/usr/bin/env bash
set -e

# [[ -L ../common ]] || ( echo "no symbolic link ../common exist" && exit 111 )

function initializer(){
    readonly -A PLACEHOLDERS=(
        [regular_chartname]=`echo $2 | gsed -r 's/(-|_)(\w)/\U\2/g'`
        [hatcher]=${1^^}
        [starter]=${1}
        [startername]=${1^}
        [port_name]=app
    )
cat << EOF > .gitignore
/charts/
EOF
    cd ..
    helm create -p ${STARTERNAME} ${CHARTNAME}
    cd -
cat << EOF >> Chart.yaml
dependencies:
  - name: common
    repository: oci://registry-1.docker.io/bitnamicharts
    # repository: file://../common
    # tags:
    #   - bitnami-common
    version: 2.x.x
EOF
    for pkey in ${!PLACEHOLDERS[@]};do
        find . \( \( -type d -name ".git" -prune \) -o -type f \) -not -name ".git" -exec \
            gsed -i'' -e "s#<PLACEHOLDER_${pkey^^}>#${PLACEHOLDERS[${pkey}]}#g" {} \;
    done
}

usage() {
cat << EOF
initialize helm charts from starter charts within a git repository.

Available Commands:
    helm hatcher init STARTERNAME   Initialize chart from starter chart STARTERNAME within a git repository.
    --help                          Display this text
EOF
}

# Create the passthru array
PASSTHRU=()
while [[ $# -gt 0 ]]
do
key="$1"

# Parse arguments
case $key in
    --help)
    HELP=TRUE
    shift # past argument
    ;;
    *)    # unknown option
    PASSTHRU+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done

# Restore PASSTHRU parameters
set -- "${PASSTHRU[@]}" 

# Show help if flagged
if [[ "$HELP" == "TRUE" ]]; then
    usage
    exit 0
fi

# COMMAND must be either 'init', 'init', or 'init'
COMMAND=${PASSTHRU[0]}

case "$COMMAND" in
    "init")
        STARTERNAME=${PASSTHRU[1]}
        CHARTNAME=`basename $(pwd)`
        git branch -a || exit 11
        [[ 0 -eq `git branch -a | wc -l` ]] || exit 17
        # git switch --create master
        initializer ${STARTERNAME} ${CHARTNAME}
        helm dependency build
        git add .
        git commit -m "initialize chart"
        exit 0
        ;;
    *)
        echo "Error: Invalid command."
        usage
        exit 1
        ;;
esac
