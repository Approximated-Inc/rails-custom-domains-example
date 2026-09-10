# frozen_string_literal: true

tenants = [
  { slug: 'atlas', name: 'Atlas Press', headline: 'Field notes for curious teams',
    body: 'Independent essays about products, places, and the people who make them.' },
  { slug: 'juniper', name: 'Juniper Journal', headline: 'Small stories, carefully published',
    body: 'A quiet publishing space for studio updates, interviews, and useful ideas.' }
]

tenants.each do |attributes|
  tenant = Tenant.find_or_initialize_by(slug: attributes.fetch(:slug))
  tenant.update!(attributes)
  domain = tenant.custom_domains.find_or_initialize_by(hostname: "#{tenant.slug}.test")
  domain.update!(lifecycle: 'fixture', status: 'local fixture', provider_id: nil,
                 is_resolving: nil, apx_hit: nil, has_ssl: nil)
end
