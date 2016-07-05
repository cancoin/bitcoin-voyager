# Bitcoin Voyager

A bitcoin blockchain explorer web application service for [libbitcoin](https://github.com/libbitcoin/libbitcoin) using the [Bitcoin Voyager API](https://github.com/cancoin/bitcoin-voyager-api)

## Quick Start

Please see the guide at [https://github.com/cancoin/bitcoin-voyager-api](https://github.com/cancoin/bitcoin-voyager-api) for information about getting a block explorer running. This repository is only the front-end component of the block explorer, and uses the full API to render data.

## Getting Started

To get the UI source code and install all of the necessary components to run Voyager locally in development mode, you can run these commands:

```
git clone git@github.com:voyager.git && cd voyager
npm install
npm run dev-server
```

Open a web browser to `http://localhost:18080`

## Development

The Voyager UI utilizes SASS for simple, application wide style changes and Mithril client side rendering. With the NPM server running, development files located in /src will compile to /build and reload active connections in your browser. 

## Views

Views are rendered using Mithril and are located in the src > views directory. Views have been templated to include header.js and footer.js on every page*. The Voyager home view is located in src > views > top_page.js, while the main container index file with <head> and <body> elements is located at src > index.html.

* Note: by default, footer elements are rendered server side on the index.html file for SEO purposes. You can also put your footer code in the footer.js template file if you wish.

## Styles

Voyager uses SASS to compile stylesheets with custom variables. All sass files are located in the src > style directory. Index.scss includes all main css styles including responsive media queries. Variables.scss includes simple colour options for the Voyager UI. To override default variables, use overrides.scss. Included variables in the variables.scss file are shown below:

```
/* Body background color */
$back-color: #ffffff;

/* Foreground / main text color */
$fore-color: #868686;

/* Border and line color */
$borders-lines: #e6e6e6;

/* Icon color */
$icons: #868686;

/* Header bar color */
$topbar: #fafafa;

/* Logo color top and bottom */
$logo: #b00201;

/* BTC orange color */
$btc-orange: #fb9316;
```

## Images

To add new images and re-build your local development environment, do the following:

1. Add your new image(s) to the src > images directory.
2. Open src > index.js and add the following line at the top of the page, one for each new image you are adding:

```
require('./images/yourimage.jpg?output= yourimage.jpg');
```

3. cd into your bitcoin-voyager repository and re-install using NPM:

```
npm install
```

4. Re-start your development server and your new images will be available in the /build directory.

npm run dev-server

## Glyphs

A Voyager glyph set has been included as a static font in the src > fonts directory. A list of the icons and their associated character is available here in PDF vector format. Below is a list of the included glyph formats:

```
voyager_glyphs.eot
voyager_glyphs.svg
voyager_glyphs.ttf
voyager_glyphs.woff
voyager_glyphs.woff2
```

## Note

For more details about the Voyager API configuration and end-points, go to the Voyager API repository.

## Contribute

Contributions and suggestions are welcomed at the Voyager API GitHub repository.

## License

LICENSE TBD
