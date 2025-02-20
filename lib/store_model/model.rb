# frozen_string_literal: true

require "store_model/types"
require "store_model/enum"
require "store_model/type_builders"
require "store_model/nested_attributes"

module StoreModel
  # When included into class configures it to handle JSON column
  module Model
    def self.included(base) # :nodoc:
      base.include ActiveModel::Model
      base.include ActiveModel::Attributes
      base.include ActiveModel::AttributeMethods
      base.include StoreModel::NestedAttributes

      base.extend StoreModel::Enum
      base.extend StoreModel::TypeBuilders

      base.attribute_method_suffix "?"
    end

    attr_accessor :parent

    # Returns a hash representing the model. Some configuration can be
    # passed through +options+.
    #
    # @param options [Hash]
    #
    # @return [Hash]
    def as_json(options = {})
      attributes.with_indifferent_access.merge(unknown_attributes).as_json(options)
    end

    # Compares two StoreModel::Model instances
    #
    # @param other [StoreModel::Model]
    #
    # @return [Boolean]
    def ==(other)
      return super unless other.is_a?(self.class)

      attributes.all? { |name, value| value == other.attributes[name] }
    end

    # Returns hash for a StoreModel::Model instance based on attributes hash
    #
    # @return [Integer]
    def hash
      attributes.hash
    end

    # Allows to call :presence validation on the association itself.
    #
    # @return [Boolean]
    def blank?
      attributes.values.all?(&:blank?)
    end

    # String representation of the object.
    #
    # @return [String]
    def inspect
      attribute_string = attributes.map { |name, value| "#{name}: #{value.nil? ? 'nil' : value}" }
                                   .join(", ")
      "#<#{self.class.name} #{attribute_string}>"
    end

    delegate :attribute_types, to: :class

    # Returns the type of the attribute with the given name
    #
    # @param attr_name [String] name of the attribute
    #
    # @return [ActiveModel::Type::Value]
    def type_for_attribute(attr_name)
      attr_name = attr_name.to_s
      attribute_types[attr_name]
    end

    # Checks if the attribute with a given name is defined
    #
    # @example
    #    class Person
    #      include StoreModel::Model
    #      attribute :name, :string
    #      alias_attribute :new_name, :name
    #    end
    #
    #    Person.has_attribute?('name')     # => true
    #    Person.has_attribute?('new_name') # => true
    #    Person.has_attribute?(:age)       # => true
    #    Person.has_attribute?(:nothing)   # => false
    #
    # @param attr_name [String] name of the attribute
    #
    # @return [Boolean]
    # rubocop:disable Naming/PredicateName
    def has_attribute?(attr_name)
      attr_name = attr_name.to_s
      attr_name = self.class.attribute_aliases[attr_name] || attr_name
      attribute_types.key?(attr_name)
    end

    # Legacy implementation of #has_attribute?
    #
    # @param attr_name [String] name of the attribute
    #
    # @return [Boolean]
    def _has_attribute?(attr_name)
      attribute_types.key?(attr_name)
    end

    # rubocop:enable Naming/PredicateName

    # Contains a hash of attributes which are not defined but exist in the
    # underlying JSON data
    #
    # @return [Hash]
    def unknown_attributes
      @unknown_attributes ||= {}
    end

    private

    def attribute?(attribute)
      case value = attributes[attribute]
      when 0 then false
      else value.present?
      end
    end
  end
end
