var React = require('react');
var {TabbedArea, TabPane} = require('react-bootstrap');
var AdminExtensions = require('./extensions.jsx');
var AdminAccounts = require('./accounts.jsx');

module.exports = AdminDashboard = React.createClass({
  render: function() {
    return (
      <TabbedArea defaultActiveKey='dashboard'>
        <TabPane eventKey='dashboard' tab='仪表盘'>
          <h1>RootPanel <small>{this.props.package.version}</small></h1>
        </TabPane>
        <TabPane eventKey='extensions' tab='插件和拓展'>
          <AdminExtensions {...this.props} />
        </TabPane>
        <TabPane eventKey='accounts' tab='用户'>
          <AdminAccounts {...this.props} />
        </TabPane>
        <TabPane eventKey='tickets' tab='工单'></TabPane>
        <TabPane eventKey='coupons' tab='优惠和兑换'></TabPane>
        <TabPane eventKey='compontents' tab='元件'></TabPane>
        <TabPane eventKey='logs' tab='系统日志'></TabPane>
      </TabbedArea>
    );
  }
});
