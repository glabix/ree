# frozen_string_literal: true

# Per-fiber stack of audited events.
#
# A stack rather than a single slot: an action is allowed to call another
# audited action, and the inner one must not steal the outer one's annotations.
#
# Thread.current[] is fiber-local in Ruby, so this is safe under Falcon as well;
# ree_datetime/functions/set_default_time_zone.rb relies on the same property.
module ReeAudit
  module Context
    KEY = :ree_audit_events

    class << self
      def push(event)
        stack << event
        event
      end

      def pop
        stack.pop
      end

      def current
        stack.last
      end

      def stack
        Thread.current[KEY] ||= []
      end

      # Leaving a stale event behind leaks one client's context into the next
      # request served by the same fiber, so the stack is always cleaned up.
      def clear
        Thread.current[KEY] = []
        nil
      end

      def empty?
        stack.empty?
      end
    end
  end
end
