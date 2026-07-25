# Namecheap API Coverage

Audited against the [official Namecheap API method index](https://www.namecheap.com/support/api/methods/) on July 25, 2026. All commands return `Namecheap::API::Response`; reads use GET and mutations use form-encoded POST. “Safe” commands run in the default sandbox smoke suite, “dry-run” mutations are exercised without submission, and “contract” commands have deterministic WebMock coverage.

| Official command | Ruby method | CLI route | Smoke |
| --- | --- | --- | --- |
| `domains.getList` | `client.domains.get_list` | `domains list` | Safe |
| `domains.getContacts` | `client.domains.get_contacts` | `domains contacts` | Lifecycle |
| `domains.create` | `client.domains.create` | `domains register` | Lifecycle |
| `domains.getTldList` | `client.domains.get_tld_list` | `domains tlds` | Safe |
| `domains.setContacts` | `client.domains.set_contacts` | `domains contacts set` | Lifecycle |
| `domains.check` | `client.domains.check` | `domains check` | Safe |
| `domains.reactivate` | `client.domains.reactivate` | `domains reactivate` | Dry-run |
| `domains.renew` | `client.domains.renew` | `domains renew` | Dry-run |
| `domains.getRegistrarLock` | `client.domains.get_registrar_lock` | `domains lock status` | Lifecycle |
| `domains.setRegistrarLock` | `client.domains.set_registrar_lock` | `domains lock set` | Dry-run |
| `domains.getInfo` | `client.domains.get_info` | `domains info` | Lifecycle |
| `domains.dns.setDefault` | `client.domains.dns.set_default` | `dns nameservers default` | Lifecycle |
| `domains.dns.setCustom` | `client.domains.dns.set_custom` | `dns nameservers custom` | Dry-run |
| `domains.dns.getList` | `client.domains.dns.get_list` | `dns nameservers list` | Lifecycle |
| `domains.dns.getHosts` | `client.domains.dns.get_hosts` | `dns records list` | Safe |
| `domains.dns.getEmailForwarding` | `client.domains.dns.get_email_forwarding` | `dns forwarding list` | Safe |
| `domains.dns.setEmailForwarding` | `client.domains.dns.set_email_forwarding` | `dns forwarding set` | Dry-run |
| `domains.dns.setHosts` | `client.domains.dns.set_hosts` | `dns records apply` | Lifecycle |
| `domains.ns.create` | `client.domains.nameservers.create` | `domains nameservers create` | Dry-run |
| `domains.ns.delete` | `client.domains.nameservers.delete` | `domains nameservers delete` | Dry-run |
| `domains.ns.getInfo` | `client.domains.nameservers.get_info` | `domains nameservers info` | Contract |
| `domains.ns.update` | `client.domains.nameservers.update` | `domains nameservers update` | Dry-run |
| `domains.transfer.create` | `client.domains.transfers.create` | `domains transfers create` | Dry-run |
| `domains.transfer.getStatus` | `client.domains.transfers.get_status` | `domains transfers status` | Contract |
| `domains.transfer.updateStatus` | `client.domains.transfers.update_status` | `domains transfers resubmit` | Dry-run |
| `domains.transfer.getList` | `client.domains.transfers.get_list` | `domains transfers list` | Safe |
| `ssl.create` | `client.ssl.create` | `ssl create` | Dry-run |
| `ssl.getList` | `client.ssl.get_list` | `ssl list` | Safe |
| `ssl.parseCSR` | `client.ssl.parse_csr` | `ssl parse-csr` | Contract |
| `ssl.getApproverEmailList` | `client.ssl.get_approver_email_list` | `ssl approver-emails` | Contract |
| `ssl.activate` | `client.ssl.activate` | `ssl activate` | Dry-run |
| `ssl.resendApproverEmail` | `client.ssl.resend_approver_email` | `ssl resend approver` | Dry-run |
| `ssl.getInfo` | `client.ssl.get_info` | `ssl info` | Contract |
| `ssl.renew` | `client.ssl.renew` | `ssl renew` | Dry-run |
| `ssl.reissue` | `client.ssl.reissue` | `ssl reissue` | Dry-run |
| `ssl.resendfulfillmentemail` | `client.ssl.resend_fulfillment_email` | `ssl resend fulfillment` | Dry-run |
| `ssl.purchasemoresans` | `client.ssl.purchase_more_sans` | `ssl sans purchase` | Dry-run |
| `ssl.revokecertificate` | `client.ssl.revoke_certificate` | `ssl revoke` | Dry-run |
| `ssl.editDCVMethod` | `client.ssl.edit_dcv_method` | `ssl dcv edit` | Dry-run |
| `users.getPricing` | `client.users.get_pricing` | `users pricing` | Safe |
| `users.getBalances` | `client.users.get_balances` | `users balances` | Safe |
| `users.changePassword` | `client.users.change_password` | `users password change` | Dry-run |
| `users.update` | `client.users.update` | `users update` | Dry-run |
| `users.createaddfundsrequest` | `client.users.create_add_funds_request` | `users funds request` | Dry-run |
| `users.getAddFundsStatus` | `client.users.get_add_funds_status` | `users funds status` | Contract |
| `users.create` | `client.users.create` | `users create` | Dry-run |
| `users.login` | `client.users.login` | `users login` | Contract |
| `users.resetPassword` | `client.users.reset_password` | `users password reset` | Dry-run |
| `users.address.create` | `client.users.addresses.create` | `users addresses create` | Lifecycle |
| `users.address.delete` | `client.users.addresses.delete` | `users addresses delete` | Lifecycle |
| `users.address.getInfo` | `client.users.addresses.get_info` | `users addresses info` | Lifecycle |
| `users.address.getList` | `client.users.addresses.get_list` | `users addresses list` | Safe |
| `users.address.setDefault` | `client.users.addresses.set_default` | `users addresses default` | Lifecycle |
| `users.address.update` | `client.users.addresses.update` | `users addresses update` | Lifecycle |
| `domainprivacy.changeemailaddress` | `client.domain_privacy.change_email_address` | `domain-privacy email rotate` | Dry-run |
| `domainprivacy.enable` | `client.domain_privacy.enable` | `domain-privacy enable` | Dry-run |
| `domainprivacy.disable` | `client.domain_privacy.disable` | `domain-privacy disable` | Dry-run |
| `domainprivacy.getList` | `client.domain_privacy.get_list` | `domain-privacy list` | Safe |
| `domainprivacy.renew` | `client.domain_privacy.renew` | `domain-privacy renew` | Dry-run |

The legacy WhoisGuard `allot`, `discard`, and `unallot` operations are intentionally excluded because they are absent from the current official catalog.
