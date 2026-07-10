# AWS Network

We are creating a VPC with three public and three private subnets, tied to availability zones `a`, `b`, and `c` of the respective region chosen, which defaults to `us-east-2` for no good reason other than it is geographically closest to me. A VPN client endpoint is also created but does not currently work. The AWS account we use for field engineering is an organizational subaccount that is not granted permission to use IAM Identity Center by the root account.

## Bastion Host

Was configured once created by running:

```sh
SUSEConnect -p PackageHub/15.7/x86_64
sudo zypper update -y
sudo zypper install -t pattern -y git gnome_basic MozillaFirefox zsh
wget https://github.com/kasmtech/KasmVNC/releases/download/v1.4.0/kasmvncserver_opensuse_15_1.4.0_x86_64.rpm
sudo zypper install -y kasmvncserver_opensuse_15_1.4.0_x86_64.rpm
sudo systemctl reboot
```

```sh
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc &&
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/zypp/repos.d/vscode.repo > /dev/null
sudo zypper addrepo https://download.opensuse.org/repositories/home:/flavio_castelli:/ghostty/15.6/home:flavio_castelli:ghostty.repo
sudo zypper addrepo https://download.opensuse.org/repositories/isv:/kubernetes:/core:/stable:/v1.35/rpm/isv:kubernetes:core:stable:v1.35.repo
sudo zypper addrepo https://download.opensuse.org/repositories/shells:/zsh-users:/zsh-autosuggestions/SLE_15/shells:zsh-users:zsh-autosuggestions.repo
sudo zypper addrepo https://download.opensuse.org/repositories/shells:/zsh-users:/zsh-syntax-highlighting/SLE_15/shells:zsh-users:zsh-syntax-highlighting.repo
sudo zypper --gpg_auto-import-keys install -y code ghostty helm kubectl zsh-autosuggestions zsh-syntax-highlighting
sudo zypper remove -y aws-cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
curl -fsSL https://releases.hashicorp.com/terraform/1.15.8/terraform_1.15.8_linux_amd64.zip -o terraform.zip
unzip terraform.zip
sudo mv terraform /usr/local/bin
curl -fsSL https://releases.hashicorp.com/packer/1.15.4/packer_1.15.4_linux_amd64.zip -o packer.zip
unzip packer.zip
sudo mv packer /usr/local/bin
curl -fsSL https://github.com/terraform-docs/terraform-docs/releases/download/v0.24.0/terraform-docs-v0.24.0-linux-amd64.tar.gz | sudo tar -C /usr/local/bin -xzf - terraform-docs
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
cat <<EOF > "$HOME/.oh-my-zsh/custom/themes/custom.zsh-theme"
if [ $UID -eq 0 ]; then NCOLOR="red"; else NCOLOR="white"; fi

PROMPT='%{$fg[$NCOLOR]%}%B%n@%m%b%{$reset_color%} %{$fg[blue]%}%B%c%b%{$reset_color%} $(git_prompt_info)%(!.#.$) '

# git theming
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}(%{$fg_no_bold[yellow]%}%B"
ZSH_THEME_GIT_PROMPT_SUFFIX="%b%{$fg_bold[blue]%})%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg_bold[red]%}✗"
EOF
cat <<EOF > "$HOME/.oh-my-zsh/custom/aliases.zsh"
alias claer='clear'
alias celar='clear'
alias caler='clear'
alias caelr='clear'
alias cler='clear'
alias clar='clear'
alias vim='nvim'
alias ls='ls --color=auto'
EOF
cat <<EOF >> "$HOME/.zshrc"
. /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
. /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
EOF
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.54.0 |
| <a name="provider_cloudinit"></a> [cloudinit](#provider\_cloudinit) | 2.4.0 |
| <a name="provider_http"></a> [http](#provider\_http) | 3.6.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_eip.bastion_ip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_iam_instance_profile.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.bastion_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_network_interface.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_network_interface_attachment.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface_attachment) | resource |
| [aws_security_group.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.allow_all_traffic_ipv4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.allow_ping](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.allow_self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.allow_ssh_ipv4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.onboarder_kasm_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.onboarder_kasm_udp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_ami.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_saml_provider.sso](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_saml_provider) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_route53_zone.domain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [cloudinit_config.bastion](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |
| [http_http.myip](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.mykeys](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_bastion_instance_type"></a> [bastion\_instance\_type](#input\_bastion\_instance\_type) | EC2 instance type for bastion host | `string` | `"m8a.2xlarge"` | no |
| <a name="input_cidr"></a> [cidr](#input\_cidr) | IPv4 CIDR range for the VPC. The default is chosen to avoid overlap with what seem to be common example ranges. | `string` | `"10.100.0.0/16"` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain that the VPN server certificate will be a subdomain of. Must be registered via AWS to use ACM. | `string` | `"rgsdemo.com"` | no |
| <a name="input_name"></a> [name](#input\_name) | tag:Name assigned to VPC, which is used by cluster provisioners to automatically find a network to attach to. | `string` | `"aacosta-demo"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region to put the VPC in. | `string` | `null` | no |
| <a name="input_sles_version"></a> [sles\_version](#input\_sles\_version) | Version of SLES to install onto bastion | `string` | `"15.7"` | no |
| <a name="input_vpn_client_cidr"></a> [vpn\_client\_cidr](#input\_vpn\_client\_cidr) | CIDR range to assign VPC client IPs from. Must not overlap with any subnet the VPC associates with. | `string` | `"172.22.0.0/16"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_server_ip"></a> [server\_ip](#output\_server\_ip) | n/a |
| <a name="output_vpc"></a> [vpc](#output\_vpc) | n/a |
<!-- END_TF_DOCS -->