import initAccountAndLimitsSection from '../account_and_limits';
import initGitpod from '../gitpod';
import initSignupRestrictions from '../signup_restrictions';

(() => {
  initAccountAndLimitsSection();
  initGitpod();
  initSignupRestrictions();
})();
