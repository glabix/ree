class ReeDto::Entity
  def to_s
    variables = self
      .instance_variables
      .map(&:to_s)
      .map { |v| v.gsub('@', '') }
      .sort

    max_length = variables.sort_by(&:size).last.size
    result     = "\n#{self.class}\n"

    result << variables
      .map { |variable|
        name = variable.to_s
        extra_spaces = ' ' * (max_length - name.size)
        %Q(  #{name}#{extra_spaces} = #{instance_variable_get("@#{variable}")})
      }
      .join("\n")

    result
  end

  def inspect
    to_s
  end

  class << self
    contract(Hash => nil)
    def properties(args)
      args.each do |name, contract_class|
        contract None => contract_class
        class_eval %Q(
          def #{name}
            @#{name}
          end
        )
      end

      contract Kwargs[**args] => Any
      class_eval %Q(
        def initialize(#{args.keys.map {|k| "#{k}: nil"}.join(',')})
          #{
            args.map {|k, v|
              "@#{k} = #{k}"
            }.join("\n")
          }
        end

        contract self => Bool
        def ==(val)
          #{
            args.map {|k, _|
              "@#{k} == val.#{k}"
            }.join(" && ")
          }
        end

        def to_h
          {
            #{args.map {|k, _| "#{k}: #{k}" }.join(", ")}
          }
        end

        def values_for(*args)
          args.map do |arg|
            variable = ("@" + arg.to_s).to_sym

            if !instance_variables.include?(variable)
              raise ArgumentError.new("variable :" + arg.to_s + " not found in dto")
            end

            instance_variable_get(variable)
          end
        end

        class << self
          def import_from(other_dto)
            self.new(
              #{
                args.map {|k, v|
                  "#{k}: other_dto.#{k}"
                }.join(",")
              }
            )
          end
        end
      )

      nil
    end
  end
end

ReeEntity = ReeDto::Entity