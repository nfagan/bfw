#include "mex.h"
#include <cstddef>
#include <cstdint>
#include <limits>
#include <cmath>

namespace {
  //  Find index of element in `t` that's closest to the `search_for`.
  //  Traverses whole array `t`.
  uint64_t find_nearest_first(double *t, uint64_t n, double search_for) {
    uint64_t idx = 0;
    double min = std::numeric_limits<double>::max();
    
    for (uint64_t i = 0; i < n; i++) {
      double diff = abs(t[i] - search_for);
      
      if (diff < min) {
        min = diff;
        idx = i;
      }
    }
    
    return idx;
  }
  
  //  Find index of element in `t` that's close to `search_for`, stopping
  //  when
  uint64_t find_nearest_next(double *t, uint64_t n, double search_for, uint64_t offset) {    
    double target = abs(t[offset] - search_for);
    uint64_t idx = offset;
    
    while (offset++ < n) {
      double current = abs(t[offset] - search_for);
      
      if (current > target) {
        break;
      }
      
      idx++;
      target = current;
    }
    
    return idx;
  }
  
  bool is_sorted_ascend(double *values, uint64_t n) {
    uint64_t i = 0;
    double last;
    bool has_value = false;
    
    while (i < n) {
      double c = values[i];
      bool is_nan = std::isnan(c);
      
      if (!is_nan && has_value && last > c) {
        return false;
      }
      
      i++;
      last = c;
      
      if (!has_value && !is_nan) {
        has_value = true;
      }
    }
    
    return true;
  }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  
  if (nrhs != 3) {
    mexErrMsgTxt("3 inputs required.");
    return;
  }
  
  if (nlhs > 1) {
    mexErrMsgTxt("Too many outputs.");
    return;
  }
  
  const mxArray *match_time = prhs[0];
  const mxArray *other_time = prhs[1];
  const mxArray *from_indices = prhs[2];
  
  if (!mxIsDouble(match_time) || !mxIsDouble(other_time) || !mxIsDouble(from_indices)) {
    mexErrMsgTxt("Inputs must be double.");
    return;
  }
  
  uint64_t n_from_indices = mxGetNumberOfElements(from_indices);
  uint64_t n_match_time = mxGetNumberOfElements(match_time);
  uint64_t n_other = mxGetNumberOfElements(other_time);
  
  double *match_time_ptr = (double*) mxGetData(match_time);
  double *other_time_ptr = (double*) mxGetData(other_time);
  double *from_indices_ptr = (double*) mxGetData(from_indices);
  
  plhs[0] = mxCreateDoubleMatrix(1, n_match_time, mxREAL);
  
  if (n_match_time == 0) {
    //  Assume at least one time point provided.
    return;
  }
  
  //  Ensure time vector + indices are sorted in ascending order.
  if (!is_sorted_ascend(match_time_ptr, n_match_time)) {
    mexErrMsgTxt("Time vector is not sorted in ascending order.");
  }
  
  if (!is_sorted_ascend(from_indices_ptr, n_from_indices)) {
    mexErrMsgTxt("Indices vector is not sorted in ascending order.");
  }
  
  double *out_ptr = (double*) mxGetData(plhs[0]);
  
  uint64_t start_offset = 0;
  const uint64_t one = static_cast<uint64_t>(1);
  bool all_valid_indices = true;
  
  for (uint64_t i = 0; i < n_from_indices; i++) {
    //  Minus one for index
    uint64_t from_index = (uint64_t) (from_indices_ptr[i] - 1.0);
    
    if (from_index >= n_other) {
      all_valid_indices = false;
      break;
    }
    
    double other_time = other_time_ptr[from_index];
    uint64_t closest_index;
    
    if (i == 0) {
      closest_index = find_nearest_first(match_time_ptr, n_match_time, other_time);
    } else {
      closest_index = find_nearest_next(match_time_ptr, n_match_time, other_time, start_offset);
    }
    
    start_offset = closest_index;
    
    out_ptr[closest_index] = (double) (from_index + one);
  }
  
  if (!all_valid_indices) {
    mexErrMsgTxt("From index is out of bounds.");
  }
}