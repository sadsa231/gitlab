# frozen_string_literal: true

module ContentSecurityPolicyHelpers
  # Expecting 2 calls to current_content_security_policy by default:
  # 1. call that's being tested
  # 2. call in ApplicationController
  def setup_csp_for_controller(
    controller_class, csp = ActionDispatch::ContentSecurityPolicy.new, times: 2,
any_time: false)
    expect_next_instance_of(controller_class) do |controller|
      if any_time
        expect(controller).to receive(:current_content_security_policy).at_least(:once).and_return(csp)
      else
        expect(controller)
        .to receive(:current_content_security_policy).exactly(times).times
        .and_return(csp)
      end
    end
  end
end
