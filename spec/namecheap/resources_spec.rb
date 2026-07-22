require "spec_helper"

# standard:disable Layout/FirstHashElementIndentation
resource_calls = {
    Namecheap::Domains => {
      get_list: [[], "domains.getList", {}],
      get_contacts: [["example.com"], "domains.getContacts", {DomainName: "example.com"}],
      create: [["example.com"], "domains.create", {DomainName: "example.com"}],
      get_tld_list: [[], "domains.getTldList", {}],
      set_contacts: [["example.com"], "domains.setContacts", {DomainName: "example.com"}],
      check: [[%w[example.com example.net]], "domains.check", {DomainList: "example.com,example.net"}],
      reactivate: [["example.com"], "domains.reactivate", {DomainName: "example.com"}],
      renew: [["example.com"], "domains.renew", {DomainName: "example.com"}],
      get_registrar_lock: [["example.com"], "domains.getRegistrarLock", {DomainName: "example.com"}],
      set_registrar_lock: [["example.com"], "domains.setRegistrarLock", {DomainName: "example.com"}],
      get_info: [["example.com"], "domains.getInfo", {DomainName: "example.com"}]
    },
    Namecheap::Dns => {
      set_default: [["example", "com"], "domains.dns.setDefault", {SLD: "example", TLD: "com"}],
      set_custom: [["example", "com", %w[ns1.example.com ns2.example.com]], "domains.dns.setCustom", {SLD: "example", TLD: "com", Nameservers: "ns1.example.com,ns2.example.com"}],
      get_list: [["example", "com"], "domains.dns.getList", {SLD: "example", TLD: "com"}],
      get_hosts: [["example", "com"], "domains.dns.getHosts", {SLD: "example", TLD: "com"}],
      get_email_forwarding: [["example.com"], "domains.dns.getEmailForwarding", {DomainName: "example.com"}],
      set_email_forwarding: [["example.com"], "domains.dns.setEmailForwarding", {DomainName: "example.com"}],
      set_hosts: [["example", "com"], "domains.dns.setHosts", {SLD: "example", TLD: "com"}]
    },
    Namecheap::Ns => {
      create: [["example", "com"], "domains.ns.create", {SLD: "example", TLD: "com"}],
      delete: [["example", "com"], "domains.ns.delete", {SLD: "example", TLD: "com"}],
      get_info: [["example", "com"], "domains.ns.getInfo", {SLD: "example", TLD: "com"}],
      update: [["example", "com"], "domains.ns.update", {SLD: "example", TLD: "com"}]
    },
    Namecheap::Transfers => {
      create: [["example.com"], "domains.transfer.create", {DomainName: "example.com"}],
      get_status: [[42], "domains.transfer.getStatus", {TransferID: 42}],
      update_status: [[42], "domains.transfer.updateStatus", {TransferID: 42}],
      get_list: [[], "domains.transfer.getList", {}]
    },
    Namecheap::Ssl => {
      activate: [[42], "ssl.activate", {CertificateID: 42}],
      get_info: [[42], "ssl.getInfo", {CertificateID: 42}],
      parse_csr: [["csr"], "ssl.parseCSR", {csr: "csr"}],
      get_approver_email_list: [["example.com"], "ssl.getApproverEmailList", {DomainName: "example.com"}],
      get_list: [[], "ssl.getList", {}],
      create: [[], "ssl.create", {}],
      renew: [[], "ssl.renew", {}],
      resend_approver_email: [[42], "ssl.resendApproverEmail", {CertificateID: 42}],
      resend_fulfillment_email: [[42], "ssl.resendfulfillmentemail", {CertificateID: 42}],
      reissue: [[42], "ssl.reissue", {CertificateID: 42}]
    },
    Namecheap::Users => {
      create: [[], "users.create", {}],
      get_pricing: [[], "users.getPricing", {}],
      get_balances: [[], "users.getBalances", {}],
      change_password: [[], "users.changePassword", {}],
      update: [[], "users.update", {}],
      create_add_funds_request: [[], "users.createaddfundsrequest", {}],
      get_add_funds_status: [[42], "users.getAddFundsStatus", {TokenId: 42}],
      login: [[], "users.login", {}],
      reset_password: [[], "users.resetPassword", {}]
    },
    Namecheap::Whois_Guard => {
      allot: [[42, "example.com"], "whoisguard.allot", {WhoisguardId: 42, DomainName: "example.com"}],
      discard: [[42], "whoisguard.discard", {WhoisguardId: 42}],
      unallot: [[42], "whoisguard.unallot", {WhoisguardId: 42}],
      disable: [[42], "whoisguard.disable", {WhoisguardId: 42}],
      enable: [[42], "whoisguard.enable", {WhoisguardId: 42}],
      change_email_address: [[42], "whoisguard.changeemailaddress", {WhoisguardId: 42}]
    }
}.freeze
# standard:enable Layout/FirstHashElementIndentation

RSpec.describe "Namecheap API resources" do
  resource_calls.each do |resource_class, calls|
    describe resource_class do
      subject(:resource) { resource_class.new }

      calls.each do |method, (arguments, command, expected_options)|
        it "maps ##{method} to #{command}" do
          expect(resource).to receive(:get).with(command, expected_options).and_return(:response)

          expect(resource.public_send(method, *arguments)).to eq(:response)
        end
      end

      it "allows explicit options to override generated options" do
        method, (arguments, command, expected_options) = calls.find { |_, (_, _, options)| !options.empty? }
        override = expected_options.keys.first

        expect(resource).to receive(:get).with(command, expected_options.merge(override => "override"))
        resource.public_send(method, *arguments, override => "override")
      end
    end
  end
end
