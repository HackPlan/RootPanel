var React = require('react');
var {Table, Button, DropdownButton, MenuItem, Modal, Input} = require('react-bootstrap');
var _ = require('lodash');
var agent = require('../scripts/agent.coffee');

module.exports = AdminAccounts = React.createClass({
  getInitialState: function() {
    return {
      accounts: this.props.accounts,
      accountDetailsModal: null,
      createDepositModal: null
    };
  },

  showAccountDetails: function(account_id) {
    this.setState({
      accountDetailsModal: account_id
    });
  },

  closeAccountDetails: function() {
    this.setState({
      accountDetailsModal: null
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

  showCreateDeposit: function(account_id) {
    this.setState({
      createDepositModal: account_id
    });
  },

  closeCreateDeposit: function() {
    this.setState({
      createDepositModal: null
    });
  },

  createDeposit: function() {
    var accountId = this.refs.depositAccountId.getValue();
    var provider = this.refs.depositProvider.getValue();
    var orderId = this.refs.depositOrderId.getValue();
    var amount = parseFloat(this.refs.depositAmount.getValue());

    agent.post(`/admin/users/${accountId}/deposits/create`, {
      provider: provider,
      orderId: orderId,
      amount: amount
    }).then( deposit => {
      alert(deposit._id);
      this.closeCreateDeposit();
    });
  },

  deleteAccount: function(account_id) {
    agent.delete(`/admin/users/${account_id}`).then( () => {
      this.setState({
        accounts: this.state.accounts.filter(function(originalAccount) {
          return originalAccount._id != account_id;
        })
      });
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
            var showAccountDetails = this.showAccountDetails.bind(this, account._id);
            var showCreateDeposit = this.showCreateDeposit.bind(this, account._id);
            var deleteAccount = this.deleteAccount.bind(this, account._id);

            if (this.state.accountDetailsModal == account._id) {
              var accountDetailsModal = <Modal show={true} onHide={this.closeAccountDetails} bsSize='large'>
                <Modal.Header closeButton>
                  <Modal.Title>{account._id}</Modal.Title>
                </Modal.Header>
                <Modal.Body>
                  <pre>{JSON.stringify(account, null, '    ')}</pre>
                </Modal.Body>
                <Modal.Footer>
                  <Button onClick={this.closeAccountDetails}>关闭</Button>
                </Modal.Footer>
              </Modal>;
            }

            if (this.state.createDepositModal == account._id) {
              var createDepositModal = <Modal show={true} onHide={this.closeCreateDeposit}>
                <Modal.Header closeButton>
                  <Modal.Title>{account._id}</Modal.Title>
                </Modal.Header>
                <Modal.Body>
                  <form className='form-horizontal'>
                    <Input ref='depositAccountId' type='text' label='用户 ID' value={account._id} labelClassName='col-xs-4' wrapperClassName='col-xs-8' />
                    <Input ref='depositProvider' type='text' label='渠道' labelClassName='col-xs-4' wrapperClassName='col-xs-8' />
                    <Input ref='depositOrderId' type='text' label='订单号' labelClassName='col-xs-4' wrapperClassName='col-xs-8' />
                    <Input ref='depositAmount' type='text' label='金额' labelClassName='col-xs-4' wrapperClassName='col-xs-8' />
                  </form>
                </Modal.Body>
                <Modal.Footer>
                  <Button bsStyle='success' onClick={this.createDeposit}>创建</Button>
                </Modal.Footer>
              </Modal>;
            }

            return (
              <tr key={account._id}>
                <td>{account.username}</td>
                <td>{account.email}</td>
                <td>{_.keys(account.plans).join()}</td>
                <td>{account.balance.toFixed(2)}</td>
                <td>
                  <Button bsStyle='info' bsSize='small' onClick={showAccountDetails}>
                    详情
                  </Button>
                  <DropdownButton title='付费计划' bsStyle='warning' bsSize='small'>
                    {this.props.plans.map( plan => {
                      var joinPlan = this.joinPlan.bind(this, account._id, plan.name);
                      var leavePlan = this.leavePlan.bind(this, account._id, plan.name);

                      if (account.plans[plan.name]) {
                        return <MenuItem key={plan.name} onSelect={leavePlan}>离开计划 {plan.name}</MenuItem>;
                      } else {
                        return <MenuItem key={plan.name} onSelect={joinPlan}>加入计划 {plan.name}</MenuItem>;
                      }
                    })}
                  </DropdownButton>
                  <DropdownButton title='操作' bsStyle='primary' bsSize='small'>
                    <MenuItem onSelect={showCreateDeposit}>确认充值</MenuItem>
                    <MenuItem onSelect={deleteAccount}>删除账号</MenuItem>
                  </DropdownButton>
                  {accountDetailsModal}
                  {createDepositModal}
                </td>
              </tr>
            )
          })}
        </tbody>
      </Table>
    )
  }
});
