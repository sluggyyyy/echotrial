const path = require('path');

module.exports = {
  entry: './src/bubble-minigame.ts',
  module: {
    rules: [
      {
        test: /\.tsx?$/,
        use: 'ts-loader',
        exclude: /node_modules/,
      },
    ],
  },
  resolve: {
    extensions: ['.tsx', '.ts', '.js'],
  },
  output: {
    filename: 'bubble-minigame.js',
    path: path.resolve(__dirname, 'html/dist'),
    clean: true,
  },
  optimization: {
    minimize: false,
  },
};