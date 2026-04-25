import { ProxyForm } from "@/components/proxy/ProxyForm";
import { PageHeader } from "@/components/common/PageHeader";

export default function NewProxyPage() {
  return (
    <div className="space-y-4">
      <PageHeader title="Create Proxy" description="Add a new HTTP or SOCKS5 proxy endpoint." />
      <ProxyForm mode="create" />
    </div>
  );
}
