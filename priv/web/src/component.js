export default class Component {
  constructor(state) {
    this.state  = state || {};
    this.client = state.client;
    this.vm     = state.vm;

    var component = this;
    this.controller = function() {
      var ctrl = {onunload: component.onUnload.bind(component)};
      component.init(ctrl);
      return ctrl;
    };
    this.controller.$original = this.init;
  }

  init(ctrl) {
  }

  onUnload() {}

  navigate(route) {
    return (evt) => {
      m.route(route)
      return false;
    }
  }

  instance() {
    var component = this;
    var controller = new this.controller();
    controller.render = function() {
      return component.view(controller);
    };
    return controller;
  }
}
