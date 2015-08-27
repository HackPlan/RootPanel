var React = require('react');
var {Table, Button, DropdownButton, MenuItem, Modal} = require('react-bootstrap');
var _ = require('lodash');
var agent = require('../scripts/agent.coffee');

module.exports = AdminComponents = React.createClass({
  getInitialState: function() {
    return {
      components: this.props.components,
      componentDetailsModal: null
    };
  },

  showComponentDetails: function(component_id) {
    this.setState({
      componentDetailsModal: component_id
    });
  },

  closeComponentDetails: function() {
    this.setState({
      componentDetailsModal: null
    });
  },

  deleteComponent: function(component_id) {
    agent.delete(`/components/${component_id}`).then( () => {
      this.setState({
        components: this.state.components.filter(function(originalComponent) {
          return originalComponent._id != component_id;
        })
      });
    });
  },

  render: function() {
    return (
      <Table hover>
        <thead>
          <tr>
            <th>用户名</th>
            <th>类型</th>
            <th>节点</th>
            <th>状态</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          {this.state.components.map( component => {
            var account = _.findWhere(this.props.accounts, {
              _id: component.account_id
            });

            if (!account) {
              account = {
                username: 'Not found'
              };
            }

            var showComponentDetails = this.showComponentDetails.bind(this, component._id);
            var deleteComponent = this.deleteComponent.bind(this, component._id);

            if (this.state.componentDetailsModal == component._id) {
              var componentDetailsModal = <Modal show={true} onHide={this.closeComponentDetails} bsSize='large'>
                <Modal.Header closeButton>
                  <Modal.Title>{component._id}</Modal.Title>
                </Modal.Header>
                <Modal.Body>
                  <pre>{JSON.stringify(component, null, '    ')}</pre>
                </Modal.Body>
                <Modal.Footer>
                  <Button onClick={this.closeComponentDetails}>关闭</Button>
                </Modal.Footer>
              </Modal>;
            }

            return (
              <tr key={component._id}>
                <td>{account.username}</td>
                <td>{component.type}</td>
                <td>{component.node}</td>
                <td>{component.status}</td>
                <td>
                  <Button bsStyle='info' bsSize='small' onClick={showComponentDetails}>
                    详情
                  </Button>
                  <DropdownButton title='操作' bsStyle='primary' bsSize='small'>
                    <MenuItem onSelect={deleteComponent}>删除元件</MenuItem>
                  </DropdownButton>
                  {componentDetailsModal}
                </td>
              </tr>
            );
          })}
        </tbody>
      </Table>
    );
  }
});
