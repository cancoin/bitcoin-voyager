var ExtractTextPlugin = require("extract-text-webpack-plugin");

module.exports = {
	verbose: false, // Set to true to show diagnostic information

	// Use preBootstrapCustomizations to change $brand-primary. Ensure this preBootstrapCustomizations does not
	// depend on other bootstrap variables.
	// preBootstrapCustomizations: "./src/style/_pre-bootstrap-customizations.scss",

	// Use bootstrapCustomizations to utilize other sass variables defined in preBootstrapCustomizations or the
	// _variables.scss file. This is useful to set one customization value based on another value.
	// bootstrapCustomizations: "./src/style/_bootstrap-customizations.scss",
	mainSass: "./src/style/index.scss",

	styleLoader: ExtractTextPlugin.extract("style-loader", "css!sass"),

	// ### Scripts
	// Any scripts here set to false will never
	// make it to the client, it's not packaged
	// by webpack.
	scripts: {
		'transition': false,
		'alert': false,
		'button': false,
		'carousel': false,
		'collapse': false,
		'dropdown': false,
		'modal': false,
		'tooltip': false,
		'popover': false,
		'scrollspy': false,
		'tab': false,
		'affix': false
	},
	// ### Styles
	// Enable or disable certain less components and thus remove
	// the css for them from the build.
	styles: {
		"mixins": true,

		"normalize": true,
		"print": true,
		"glyphicons": false,

		"scaffolding": false,
		"type": true,
		"code": false,
		"grid": true,
		"tables": false,
		"forms": false,
		"buttons": true,

		"component-animations": true,
		"dropdowns": false,
		"button-groups": false,
		"input-groups": false,
		"navs": false,
		"navbar": false,
		"breadcrumbs": false,
		"pagination": false,
		"pager": false,
		"labels": false,
		"badges": false,
		"jumbotron": false,
		"thumbnails": false,
		"alerts": false,
		"progress-bars": false,
		"media": false,
		"list-group": false,
		"panels": false,
		"wells": false,
		"responsive-embed": false,
		"close": false,

		"modals": false,
		"tooltip": false,
		"popovers": false,
		"carousel": false,

		"utilities": false,
		"responsive-utilities": false
	}
};
