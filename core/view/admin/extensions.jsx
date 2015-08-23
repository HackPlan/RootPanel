var {Row, Col, Panel} = require('react-bootstrap');
var React = require('react');
var _ = require('lodash');

module.exports = AdminExtensions = React.createClass({
  render: function() {
    var {plugins, plans} = this.props;

    return (
      <div>
        <Row>
          <header>付费方案</header>
          {plans.map(function(plan) {
            return (
              <Col md={3} key={plan.name}>
                <Panel header={plan.name}>
                  <p>join_freely: {plan.join_freely.toString()}</p>
                  <p>components: {_.keys(plan.components).join()}</p>
                  <p>billing: {_.keys(plan.billing).join()}</p>
                  <p>users: {plan.users}</p>
                </Panel>
              </Col>
            );
          })}
        </Row>
        <Row>
          <header>插件</header>
          {plugins.map(function(plugin) {
            return (
              <Col md={6} key={plugin.name}>
                <Panel header={plugin.name}>
                  <p>dependencies: {_.keys(plugin.dependencies).join()}</p>
                  <p>routes: {_.pluck(plugin.registered.routers, 'path').join()}</p>
                  <p>hooks: {_.pluck(plugin.registered.hooks, 'path').join()}</p>
                  <p>views: {_.pluck(plugin.registered.views, 'view').join()}</p>
                  <p>widgets: {_.pluck(plugin.registered.widgets, 'view').join()}</p>
                  <p>components: {_.pluck(plugin.registered.components, 'name').join()}</p>
                  <p>couponTypes: {_.pluck(plugin.registered.couponTypes, 'name').join()}</p>
                  <p>paymentProviders: {_.pluck(plugin.registered.paymentProviders, 'name').join()}</p>
                </Panel>
              </Col>
            );
          })}
        </Row>
      </div>
    );
  }
});
