FactoryBot.define do

  factory :group, class: Keepassx::Group do
    id    { 1 }
    name  { 'test_group' }
    icon  { 20 }

    initialize_with { new(attributes) }
  end

  factory :entry, class: Keepassx::Entry do
    name      { 'test_entry' }
    group     { build(:group) }
    username  { 'test' }
    password  { 'test' }
    icon      { 20 }
    url       { 'https://example.com' }
    notes     { 'Test comment' }

    initialize_with { new(attributes) }
  end

end
