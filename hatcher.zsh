#!/usr/bin/env zsh
set -e

# [[ -L ../common ]] || ( echo "no symbolic link ../common exist" && exit 111 )

function initializer(){
    readonly -A PLACEHOLDERS=(
        [regular_chartname]=`echo $2 | gsed -r 's/(-|_)(\w)/\U\2/g'`
        [hatcher]=${(U)1}
        [starter]=${1}
        [startername]=${(C)1}
        [port_name]=app
    )
cat << EOF > .gitignore
/charts/
# Various IDEs
.project
.idea/
*.tmproj
.vscode/
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
    for pkey in ${(@k)PLACEHOLDERS};do
        find . \( \( -type d -name ".git" -prune \) -o -type f \) -not -name ".git" -exec \
            gsed -i'' -e "s#<PLACEHOLDER_${(U)pkey}>#${PLACEHOLDERS[${pkey}]}#g" {} \;
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
    case $key in
        --help)
            HELP=TRUE
            shift
            ;;
        *)
            PASSTHRU+=("$1")
            shift
            ;;
    esac
done

# Restore PASSTHRU parameters
set -- "${(@v)PASSTHRU}" 

# Show help if flagged
if [[ "$HELP" == "TRUE" ]]; then
    usage
    exit 0
fi

# COMMAND must be either 'init', 'init', or 'init'
COMMAND=${PASSTHRU[1]}

case "$COMMAND" in
    "init")
        STARTERNAME=${PASSTHRU[2]}
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
