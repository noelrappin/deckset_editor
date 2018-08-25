module.exports = {
  mode: "development",
  entry: './src/static/index.js',
  output: {
      path: __dirname + '/dist',
      publicPath: "/assets/",
      filename: 'bundle.js'
  },
  module: {
    rules: [
      {
        test:    /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: {
          loader: 'elm-webpack-loader',
          options: {}
        }
      }
    ]
  },
  resolve: {
    extensions: ['.js', '.elm']
  },
  devServer: { inline: true }
}
