#include "osqp/osqp.h"        // OSQP API
#include "osqp/cs.h"          // CSC data structure
#include "osqp/util.h"        // Utilities for testing
#include "osqp_tester.h" // Basic testing script header

#include "primal_infeasibility/data.h"


void test_primal_infeasible_qp_solve()
{
  c_int exitflag;

  // Problem settings
  OSQPSettings *settings = (OSQPSettings *)c_malloc(sizeof(OSQPSettings));

  // Structures
  OSQPWorkspace *work; // Workspace
  OSQPData *data;      // Data
  primal_infeasibility_sols_data *sols_data;

  // Populate data
  data      = generate_problem_primal_infeasibility();
  sols_data = generate_problem_primal_infeasibility_sols_data();


  // Define Solver settings as default
  osqp_set_default_settings(settings);
  settings->max_iter   = 10000;
  settings->alpha      = 1.6;
  settings->polish     = 1;
  settings->scaling    = 0;
  settings->verbose    = 1;
  settings->warm_start = 0;

  // Setup workspace
  exitflag = osqp_setup(&work, data, settings);

  // Setup correct
  mu_assert("Primal infeasible QP test solve: Setup error!", exitflag == 0);

  // Solve Problem
  osqp_solve(work);

  // Compare solver statuses
  mu_assert("Primal infeasible QP test solve: Error in solver status!",
            work->info->status_val == sols_data->status_test);


  // Clean workspace
  osqp_cleanup(work);


  // Cleanup data
  clean_problem_primal_infeasibility(data);
  clean_problem_primal_infeasibility_sols_data(sols_data);

  // Cleanup
  c_free(settings);
}