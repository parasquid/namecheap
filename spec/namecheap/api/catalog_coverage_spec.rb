require "spec_helper"
require "namecheap/cli/catalog"

RSpec.describe "official Namecheap API catalog coverage" do
  let(:client) do
    Namecheap::API::Client.new(
      api_user: "api-user",
      api_key: "api-key",
      user_name: "account-user",
      client_ip: "192.0.2.1"
    )
  end

  def coverage
    {
      domains: {
        get_list: "domains list",
        get_contacts: "domains contacts",
        create: "domains register",
        get_tld_list: "domains tlds",
        set_contacts: "domains contacts set",
        check: "domains check",
        reactivate: "domains reactivate",
        renew: "domains renew",
        get_registrar_lock: "domains lock status",
        set_registrar_lock: "domains lock set",
        get_info: "domains info"
      },
      dns: {
        set_default: "dns nameservers default",
        set_custom: "dns nameservers custom",
        get_list: "dns nameservers list",
        get_hosts: "dns records list",
        get_email_forwarding: "dns forwarding list",
        set_email_forwarding: "dns forwarding set",
        set_hosts: "dns records apply"
      },
      nameservers: {
        create: "domains nameservers create",
        delete: "domains nameservers delete",
        get_info: "domains nameservers info",
        update: "domains nameservers update"
      },
      transfers: {
        create: "domains transfers create",
        get_status: "domains transfers status",
        update_status: "domains transfers resubmit",
        get_list: "domains transfers list"
      },
      ssl: {
        create: "ssl create",
        get_list: "ssl list",
        parse_csr: "ssl parse-csr",
        get_approver_email_list: "ssl approver-emails",
        activate: "ssl activate",
        resend_approver_email: "ssl resend approver",
        get_info: "ssl info",
        renew: "ssl renew",
        reissue: "ssl reissue",
        resend_fulfillment_email: "ssl resend fulfillment",
        purchase_more_sans: "ssl sans purchase",
        revoke_certificate: "ssl revoke",
        edit_dcv_method: "ssl dcv edit"
      },
      users: {
        get_pricing: "users pricing",
        get_balances: "users balances",
        change_password: "users password change",
        update: "users update",
        create_add_funds_request: "users funds request",
        get_add_funds_status: "users funds status",
        create: "users create",
        login: "users login",
        reset_password: "users password reset"
      },
      addresses: {
        create: "users addresses create",
        delete: "users addresses delete",
        get_info: "users addresses info",
        get_list: "users addresses list",
        set_default: "users addresses default",
        update: "users addresses update"
      },
      domain_privacy: {
        change_email_address: "domain-privacy email rotate",
        enable: "domain-privacy enable",
        disable: "domain-privacy disable",
        get_list: "domain-privacy list",
        renew: "domain-privacy renew"
      }
    }
  end

  def resource(name)
    case name
    when :domains then client.domains
    when :dns then client.domains.dns
    when :nameservers then client.domains.nameservers
    when :transfers then client.domains.transfers
    when :ssl then client.ssl
    when :users then client.users
    when :addresses then client.users.addresses
    when :domain_privacy then client.domain_privacy
    end
  end

  it "maps all 59 official commands to explicit Ruby methods and CLI routes" do
    expect(coverage.values.sum(&:length)).to eq(59)

    coverage.each do |resource_name, commands|
      commands.each do |method_name, cli_path|
        expect(resource(resource_name)).to respond_to(method_name)
        expect(Namecheap::CLI::Catalog.find(cli_path.split)).not_to be_nil
      end
    end
  end
end
