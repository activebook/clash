import urllib.request
import re
import ipaddress

# URLs for the lists
# Using felixonmars/dnsmasq-china-list for domains (well maintained)
DOMAIN_LIST_URL = "https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf"
# Using ACL4SSR for IPs (still good for company IPs)
IP_LIST_URL = "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/ChinaCompanyIp.list"

# Proxy setting
PROXY_STRING = "PROXY 192.168.31.94:3128"

def download_list(url):
    print(f"Downloading {url}...")
    try:
        with urllib.request.urlopen(url) as response:
            return response.read().decode('utf-8')
    except Exception as e:
        print(f"Error downloading {url}: {e}")
        return ""

def parse_domain_list(content):
    suffixes = set()
    # Format: server=/example.com/114.114.114.114
    for line in content.splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        
        # Extract domain from server=/domain/...
        match = re.search(r'server=/(.+?)/', line)
        if match:
            domain = match.group(1)
            suffixes.add(domain)
            
    return sorted(list(suffixes)), [] # No keywords in this list format

def parse_ip_list(content):
    cidrs = []
    for line in content.splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue
            
        parts = line.split(',')
        if len(parts) < 2:
            continue
            
        type_ = parts[0].strip()
        value = parts[1].strip()
        
        if type_ == 'IP-CIDR':
            try:
                # Verify it's a valid CIDR
                ipaddress.ip_network(value, strict=False)
                cidrs.append(value)
            except ValueError:
                print(f"Invalid CIDR ignored: {value}")
                
    return cidrs

def generate_pac(suffixes, keywords, cidrs):
    # JavaScript template
    js_template = """
var proxy = "%s";
var direct = "DIRECT";

var directSuffixes = {
%s
};

var directCIDRs = [
%s
];

function FindProxyForURL(url, host) {
    // 1. Check if host is plain hostname (no dots)
    if (isPlainHostName(host)) {
        return direct;
    }

    // 2. Check Domain Suffixes (Optimized with object lookup)
    var lastDot = host.lastIndexOf('.');
    if (lastDot !== -1) {
        var parts = host.split('.');
        for (var i = 0; i < parts.length; i++) {
            var domain = parts.slice(i).join('.');
            if (directSuffixes.hasOwnProperty(domain)) {
                return direct;
            }
        }
    }

    // 3. Check IPs
    var ipRegex = /^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$/;
    if (ipRegex.test(host)) {
        for (var i = 0; i < directCIDRs.length; i++) {
            var cidr = directCIDRs[i];
            var split = cidr.split('/');
            var ip = split[0];
            var mask = split[1];
            if (isInNet(host, ip, convertMask(mask))) {
                return direct;
            }
        }
    }

    return proxy;
}

function convertMask(bitCount) {
    var mask = [];
    for(var i=0; i<4; i++) {
        var n = Math.min(bitCount, 8);
        mask.push(256 - Math.pow(2, 8-n));
        bitCount -= n;
    }
    return mask.join('.');
}
"""
    
    # Format data for JS
    formatted_suffixes = ",\n".join([f'    "{s}": 1' for s in suffixes])
    formatted_cidrs = ",\n".join([f'    "{c}"' for c in cidrs])
    
    return js_template % (PROXY_STRING, formatted_suffixes, formatted_cidrs)

def main():
    print("Fetching Domain List (felixonmars)...")
    domain_content = download_list(DOMAIN_LIST_URL)
    suffixes, _ = parse_domain_list(domain_content)
    print(f"Found {len(suffixes)} domains.")
    
    print("Fetching IP List...")
    ip_content = download_list(IP_LIST_URL)
    cidrs = parse_ip_list(ip_content)
    print(f"Found {len(cidrs)} IP ranges.")
    
    print("Generating proxy.pac...")
    pac_content = generate_pac(suffixes, [], cidrs)
    
    with open('proxy.pac', 'w') as f:
        f.write(pac_content)
    
    print("Done! proxy.pac generated.")

if __name__ == "__main__":
    main()
