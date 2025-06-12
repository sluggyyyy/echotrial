const path = require('path');

module.exports = {
  entry: './src/money-counter-audio.ts',
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
    filename: 'money-counter-audio.js',
    path: path.resolve(__dirname, 'html/dist'),
    clean: true,
  },
  optimization: {
    minimize: false,
  },
};