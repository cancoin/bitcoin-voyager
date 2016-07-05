var path = require('path');
var webpack = require('webpack');
var ExtractTextPlugin = require('extract-text-webpack-plugin');

var srcDiir = path.join(__dirname, 'src')

module.exports = {
    entry: [
        './src/voyager_client.js'
    ],
    output: {
        path: path.join(__dirname, 'build'),
        filename: 'voyager_client.js'
    },
    resolve: { root: [path.join(__dirname, 'bower_components')] },
    plugins: [
        new webpack.optimize.UglifyJsPlugin({
            sourceMap: true,
            mangle: false,
            compress: { warnings: false }
        })
    ],
    module: {
        loaders: [
            {
                test: /\.js?$/,
                loader: 'babel',
                exclude: /(node_modules|bower_components)/
            },
            {
                test: /bootstrap-sass\/assets\/javascripts\//,
                loader: 'imports'
            }
        ]
    }
};

