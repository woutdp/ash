defmodule Ash.Resource.Relationships.SharedOptions do
  @moduledoc false

  @shared_options [
    name: [
      type: :atom,
      doc: "The name of the relationship"
    ],
    destination: [
      type: :ash_resource,
      doc: "The destination resource"
    ],
    destination_field: [
      type: :atom,
      doc:
        "The field on the related resource that should match the `source_field` on this resource."
    ],
    validate_destination_field?: [
      type: :boolean,
      default: true,
      doc:
        "Whether or not to validate that the destination field exists on the destination resource"
    ],
    source_field: [
      type: :atom,
      doc:
        "The field on this resource that should match the `destination_field` on the related resource."
    ],
    description: [
      type: :string,
      doc: "An optional description for the relationship"
    ],
    relationship_context: [
      type: :any,
      as: :context,
      doc: """
      Context to be set on any queries or changesets generated for this relationship.

      This is used by ash_postgres for polymorphic resources.
      """
    ],
    private?: [
      type: :boolean,
      default: false,
      doc:
        "Whether or not the relationship will appear in any interfaces created off of this resource, e.g AshJsonApi and AshGraphql"
    ],
    not_found_message: [
      type: :string,
      doc: """
      A message to show if there is a conflict with this relationship in the database on update or create.

      For example, if a value is added that has no match in the destination (very hard to do with the way Ash relationship changes work).
      """
    ],
    writable?: [
      type: :boolean,
      default: true,
      doc: """
      Wether or not the relationship may be edited.
      """
    ],
    read_action: [
      type: :atom,
      doc: """
      The read action on the destination resource to use when loading data.

      Keep in mind, any filters that exist on the destination action are not honored when filtering on this
      relationship. The only time the read action comes into play is when loading the actual relationship, which happens when they are loaded
      explicitly and when the relationship is managed.
      """
    ],
    api: [
      type: :atom,
      doc: """
      The API module to use when working with the related entity.
      """
    ],
    filter: [
      type: :any,
      doc: """
      A filter to be applied when reading the relationship.
      """
    ],
    sort: [
      type: :any,
      doc: """
      A sort statement to be applied when reading the relationship.
      """
    ],
    could_be_related_at_creation?: [
      type: :boolean,
      default: false,
      doc: """
      This toggle modifies the management of the relationship. Typically, on creation,
      the existing value of the relationship isn't loaded. However, if it is possible for things
      to be related *before* this record is created, for example if your data layers does not support
      primary keys, then you should set this to true.
      """
    ],
    violation_message: [
      type: :string,
      doc: """
      A message to show if there is a conflict with this relationship in the database on destroy.
      For example, if a record is deleted while related records still exist (and aren't configured to cascade deletes)
      """
    ]
  ]

  def shared_options do
    @shared_options
  end

  def no_fields do
    {:no_fields?,
     [
       type: :boolean,
       doc: """
       If true, all existing entities are considered related, i.e this relationship is not based on any fields, and `source_field` and
       `destination_field` are ignored.

       This can be very useful when combined with multitenancy. Specifically, if you have a tenant resource like `Organization`,
       you can use `no_fields?` to do things like `has_many :employees, Employee, no_fields?: true`, which lets you avoid having an
       unnecessary `organization_id` field on `Employee`. The same works in reverse: `has_one :organization, Organization, no_fields?: true`
       allows relating the employee to their organization.

       Some important caveats here:

       1. You can still manage relationships from one to the other, but "relate" and "unrelate"
       will have no effect, because there are no fields to change.

       2. Loading the relationship on a list of resources will not behave as expected in all circumstances involving multitenancy. For example,
          if you get a list of `Organization` and then try to load `employees`, you would need to set a single tenant on the load query, meaning
          you'll get all organizations back with the set of employees from one tenant. This could eventually be solved, but for now it is considered an
          edge case.
       """
     ]}
  end

  def manual do
    {:manual,
     type: {:ash_behaviour, Ash.Resource.ManualRelationship},
     doc: """
     Allows for relationships that are fetched manually. WARNING: EXPERIMENTAL

     Manual relationships do not support filters or aggregates at the moment. In the future, what we may do is
     allow the data layer to be configured with a hook that expresses how to implement this manual relationship
     at the data layer level, like providing a custom ecto join for ash_postgres. This is the simple groundwork
     for that.

     ```elixir
     # in the resource
     relationships do
       has_many :somethings, MyApp.Something do
         manual {MyApp.FetchSomethings, [opt1: :value]}
         # or if there are no opts
         # manual MyApp.FetchSomethings
       end
     end

     # the implementation
     defmodule MyApp.FetchSomethings do
       use Ash.Resource.ManualRelationship

       def load(records, _opts, %{relationship: relationship}) do
         # Return a map of primary keys of the records to the related records.
         # This example is likely suboptimal because it does a separate fetch for
         # each record, whereas you likely want to try to fetch them all at once,
         # and then create the mapping from pkey values to related records
         # For example:

         # get the primary key
         primary_key = Ash.Resource.Info.primary_key(relationship.source)
         # e.g [:id]

         # key the records by primary key and the related records with that primary key
         {:ok,
           Map.new(records, fn record ->
             # the key is the pkey values, e.g `%{id: 1}`
             # the value is the related records for that record
             {Map.take(record, primary_key), get_related_records(record)}
           end)}
       end
     end
     ```
     """}
  end
end
