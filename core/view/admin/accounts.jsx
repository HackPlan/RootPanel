var React = require('react');
var {Table, Button, DropdownButton, MenuItem, Modal} = require('react-bootstrap');
var _ = require('lodash');
var agent = require('../scripts/agent.coffee');
var Cookies = require('js-cookie');
var $ = require('jquery');

module.exports = AdminAccounts = React.createClass({
  getInitialState: function() {
    return {
      accounts: this.props.accounts
    };
  },

  componentDidMount: function() {
    $.ajaxSetup({
      headers: {'X-Token': Cookies.get('token')}
    });
  },

  showAccountDetails: function(account_id) {
    this.setState({
      detailsModal: account_id
    });
  },

  closeAccountDetails: function() {
    this.setState({
      detailsModal: null
    });
  },

  joinPlan: function(account_id, plan_name) {
    agent.post(`/admin/users/${account_id}/plans/join`, {
      plan: plan_name
    }).then( account => {
      this.updateAccount(account);
    });
  },

  leavePlan: function(account_id, plan_name) {
    agent.post(`/admin/users/${account_id}/plans/leave`, {
      plan: plan_name
    }).then( account => {
      this.updateAccount(account);
    });
  },

  updateAccount: function(account) {
    this.setState({
      accounts: this.state.accounts.map(function(originalAccount) {
        if (originalAccount._id == account._id) {
          return account;
        } else {
          return originalAccount;
        }
      })
    });
  },

  render: function() {
    return (
      <Table hover>
        <thead>
          <tr>
            <th>用户名</th>
            <th>邮箱</th>
            <th>付费计划</th>
            <th>余额</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          {this.state.accounts.map( account => {
            return (
              <tr key={account._id}>
                <td>{account.username}</td>
                <td>{account.email}</td>
                <td>{_.keys(account.plans).join()}</td>
                <td>{account.balance.toFixed(2)}</td>
                <td>
                  <Button bsStyle='info' bsSize='small' onClick={this.showAccountDetails.bind(this, account._id)}>
                    详情
                  </Button>
                  {this.state.detailsModal == account._id && (
                    <Modal show={true} onHide={this.closeAccountDetails} bsSize='large'>
                      <Modal.Header closeButton>
                        <Modal.Title>{account._id}</Modal.Title>
                      </Modal.Header>
                      <Modal.Body>
                        <pre>{JSON.stringify(account, null, '    ')}</pre>
                      </Modal.Body>
                      <Modal.Footer>
                        <Button onClick={this.closeAccountDetails}>关闭</Button>
                      </Modal.Footer>
                    </Modal>
                  )}
                  <DropdownButton title='付费计划' bsStyle='warning' bsSize='small'>
                    {this.props.plans.map( plan => {
                      if (account.plans[plan.name]) {
                        return <MenuItem key={plan.name} className='bg-danger' eventKey={plan.name} onSelect={this.leavePlan.bind(this, account._id)}>离开计划 {plan.name}</MenuItem>;
                      } else {
                        return <MenuItem key={plan.name} className='bg-success' eventKey={plan.name} onSelect={this.joinPlan.bind(this, account._id)}>加入计划 {plan.name}</MenuItem>;
                      }
                    })}
                  </DropdownButton>
                  <DropdownButton title='操作' bsStyle='primary' bsSize='small'>
                    <MenuItem>确认充值</MenuItem>
                    <MenuItem>删除账号</MenuItem>
                  </DropdownButton>
                </td>
              </tr>
            )
          })}
        </tbody>
      </Table>
    )
  }
});
