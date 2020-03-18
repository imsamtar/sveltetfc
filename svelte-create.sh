log=''
install='npm i --loglevel silent '

function clearScr() {
    clear -x
}

function printLog() {
    if [ "$1" ]; then
        if [ "$log" ]; then
            log=$log'\n'$1
        else
            log=$1
        fi
    fi
    sleep 0.25
    clearScr
    echo -e $log
}

if [ $1 ] && [ $1 == 'update' ]; then
    cd /tmp
    git clone https://github.com/imsamtar/svelte-create.git
    cd svelte-create
    ./install
    cd /tmp
    rm -rf svelte-create
    exit
fi
if [ -z "$1" ]; then
    set "."
fi
if [ -d $1 ]; then
    if [ -z "$(ls -A $1)" ]; then
        cd $1
    else
        echo -e "\n> '$1' is not empty\n"
        exit
    fi
elif [ -f $1 ]; then
    echo -e "\n> File named '$1' already exists\n"
    exit
else
    mkdir $1
    cd $1
fi

printLog "+ Cloning svelte template for webpack..."
npx degit sveltejs/template-webpack .
clearScr
read -p "Enter package name (small letters): [$(basename $PWD)]" pkgname

printLog
if [ -z $pkgname ]; then pkgname="$(basename $PWD)"; fi
sed -i 's/svelte-app/'$pkgname'/g' package.json
sed -i 's/webpack-dev-server /webpack-dev-server --port 3000 /g' package.json
sed -i 's/localhost:8080/localhost:3000/g' README.md

printLog "+ Updating postcss.config.js..."
echo -e "const purgecss = require('@fullhuman/postcss-purgecss')({
\tcontent: ['./src/**/*.html', './src/**/*.svelte'],
\twhitelistPatterns: [/svelte-/],
\tdefaultExtractor: content => content.match(/[A-Za-z0-9-_:/]+/g) || []
});
const production = process.env.NODE_ENV==='production';
module.exports = {
\tplugins: [
\t\trequire('tailwindcss'),
\t\t...(production ? [purgecss] : [])
\t]
};" >postcss.config.js

printLog "+ Creating src/Tailwind.svelte..."
echo -e "<style global>
\t@tailwind base;
\t@tailwind components;
\t@tailwind utilities;
</style>" >src/Tailwind.svelte

printLog "+ Updating src/App.svelte..."
sed -i "s/<script>/<script>\n\timport Tailwind from \'.\/Tailwind.svelte';/g" src/App.svelte

printLog "+ Updating webpack.config.js..."
sed -i "s/options: {/options: {\n\t\t\t\t\t\tpreprocess: require('svelte-preprocess')({ postcss: true }),/g" webpack.config.js

printLog "+ Installing svelte dependencies..."
$install
printLog "+ Installing tailwind dependencies..."
$install --save-dev tailwindcss @fullhuman/postcss-purgecss postcss postcss-load-config svelte-preprocess
printLog "+ Initializing tailwind configuration file..."
npx tailwind init --full
printLog
read -p "Do you want to setup for hasura? [Y] " hasura

printLog
if [ -z $hasura ]; then hasura="y"; fi
if [ $hasura != "n" ] && [ $hasura != "N" ]; then
    printLog "+ Installing graphql dependencies..."
    $install --save-dev apollo-cache-inmemory apollo-client apollo-link apollo-link-error apollo-link-http apollo-link-ws graphql graphql-tag subscriptions-transport-ws
    echo "import { split } from 'apollo-link';
import { HttpLink } from 'apollo-link-http';
import { WebSocketLink } from 'apollo-link-ws';
import { getMainDefinition } from 'apollo-utilities';
import ApolloClient from 'apollo-client';
import { InMemoryCache } from 'apollo-cache-inmemory';

// Create an http link:
const httpLink = new HttpLink({
    uri: 'http://localhost:8080/v1/graphql'
});

// Create a WebSocket link:
const wsLink = new WebSocketLink({
    uri: 'ws://localhost:8080/v1/graphql',
    options: {
        reconnect: true
    }
});

// using the ability to split links, you can send data to each link
// depending on what kind of operation is being sent
const link = split(
    // split based on operation type
    ({ query }) => {
        const definition = getMainDefinition(query);
        return (
            definition.kind === 'OperationDefinition' &&
            definition.operation === 'subscription'
        );
    },
    wsLink,
    httpLink,
);

export default new ApolloClient({
    link,
    cache: new InMemoryCache(),
});
" >src/graphql-client.js
fi

printLog
read -p "Do you want to install firebase? [Y] " firebase
printLog
if [ -z $firebase ]; then firebase="y"; fi
if [ $firebase != "n" ] && [ $firebase != "N" ]; then
    printLog "+ Installing firebase..."
    $install --save-dev @firebase/app @firebase/auth
    printLog
fi

if [ -z "$(which cypress)" ] || [ $firebase != 'n' ] && [ $firebase != 'N' ]; then
    read -p "Do you want to install Cypress? [Y] " cypress
    printLog
    if [ -z $cypress ]; then cypress="y"; fi
    if [ $cypress != "n" ] && [ $cypress != "N" ]; then
        if ! [ -z $firebase ] && [ $firebase != "n" ] && [ $firebase != "N" ]; then
            printLog "+ Installing cypress-firebase..."
            $install --save-dev cypress-firebase
        fi

        if [ -z "$(which cypress)" ]; then
            read -p "Install cypress globally? [N] " cypress
            printLog
            if [ -z $cypress ]; then cypress="n"; fi
            if [ $cypress = "y" ] || [ $cypress = "Y" ]; then
                printLog "+ Installing cypress globally..."
                $install -g cypress
            fi
        fi
    fi
    printLog
fi
printLog
