#include "mex.h"
#include "find_nearest_sorted_version.hpp"
#include <cstdint>
#include <string>
#include <cstring>
#include <cmath>

namespace {
  template <typename T>
  struct DecomposedArray {
    T *data;
    int64_t size;
  };
  
  bool is_sorted_ascending(double *elements, int64_t N) {   
    for (int64_t i = 0; i < N-1; i++) {
      if (elements[i] > elements[i+1]) {
        return false;
      }
    }
    
    return true;
  }
  
  void check_sorted(const mxArray *array, const char* const var_name) {
    double *array_ptr = mxGetPr(array);
    int64_t n_array_elements = mxGetNumberOfElements(array);

    if (!is_sorted_ascending(array_ptr, n_array_elements)) {
      std::string string_var_name = std::string(var_name) + " array is not sorted.";
      mexErrMsgTxt(string_var_name.c_str());
    }
  }
  
  bool determine_to_check_is_sorted(const mxArray *logical_flag) {
    if (!mxIsLogicalScalar(logical_flag)) {
      mexErrMsgTxt("Check sorting flag must be a logical scalar.");
    }
    
    return mxIsLogicalScalarTrue(logical_flag);
  }
  
  void check_inputs(const mxArray *time_array, const mxArray *events_array, bool check_is_sorted) {
    if (!mxIsDouble(time_array) || !mxIsDouble(events_array)) {
      mexErrMsgTxt("Time and event arrays must be double arrays.");
    }
    
    if (mxIsComplex(time_array) || mxIsComplex(events_array)) {
      mexErrMsgTxt("Time and event arrays must be real double arrays.");
    }
    
    if (check_is_sorted) {
      check_sorted(time_array, "time");
      check_sorted(events_array, "events");
    }
  }
  
  DecomposedArray<double> decompose_double_array(const mxArray *array) {
    DecomposedArray<double> result;
    
    result.data = mxGetPr(array);
    result.size = mxGetNumberOfElements(array);
    
    return result;
  }
  
  template <typename T>
  DecomposedArray<T> decompose_numeric_array(const mxArray *array) {
    DecomposedArray<T> result;
    
    result.data = (T*)(mxGetData(array));
    result.size = mxGetNumberOfElements(array);
    
    return result;
  }
  
  int64_t binary_search(DecomposedArray<double> &time, double search_for) {
    if (time.size == 0) {
      return 1;
    }
    
    int64_t i = 0;
    int64_t j = time.size - 1;
    int64_t mid = 0;
    
    while (i <= j) {
      mid = i + (j - i) / 2;
      
      double t = time.data[mid];
      
      if (search_for == t) {
        return mid + 1;
        
      } else if (search_for < t) {
        j = mid - 1;
        
      } else {
        i = mid + 1;
      }
    }
    
    int64_t candidate_ind = mid;
    int64_t left_adjacent = candidate_ind - 1;
    int64_t right_adjacent = candidate_ind + 1;
    
    double candidate_difference = std::abs(search_for - time.data[candidate_ind]);
    
    if (left_adjacent >= 0) {
      double left_difference = std::abs(search_for - time.data[left_adjacent]);
      
      if (left_difference < candidate_difference) {
        candidate_difference = left_difference;
        candidate_ind = left_adjacent;
      }
    }
    
    if (right_adjacent < time.size) {
      double right_difference = std::abs(search_for - time.data[right_adjacent]);
      
      if (right_difference < candidate_difference) {
        candidate_difference = right_difference;
        candidate_ind = right_adjacent;
      }
    }
    
    return (candidate_ind + 1);
  }
  
  void find_indices_binary(DecomposedArray<double> time,
                           DecomposedArray<double> events,
                           DecomposedArray<int64_t> out_indices) {
    
    for (int64_t i = 0; i < events.size; i++) {
      double event = events.data[i];
      
      if (std::isnan(event)) {
        out_indices.data[i] = 1;
      } else {
        out_indices.data[i] = binary_search(time, event);
      }
    }
  }
  
  void find_indices(DecomposedArray<double> time, 
                    DecomposedArray<double> events, 
                    DecomposedArray<int64_t> out_indices) {
    
    int64_t time_index = 0;
    int64_t last_time_index = 0;
    
    for (int64_t i = 0; i < events.size; i++) {
      double event_time = events.data[i];
      
      if (std::isnan(event_time)) {
        out_indices.data[i] = 1;
        continue;
      }
      
      int64_t assign_index = 0;
      bool found_match = false;
      
      for (int64_t j = time_index; j < time.size; j++) {
        double t = time.data[j];
        
        if (std::isnan(t)) {
          continue;
        }
        
        double current_difference = std::abs(event_time - t);
        
        if (j - last_time_index > 0) {
          double last_t = time.data[last_time_index];
          double last_difference = std::abs(event_time - last_t);
          
          if (last_difference <= current_difference) {
            assign_index = last_time_index + 1;
            time_index = last_time_index;
            found_match = true;
          }
        }
        
        last_time_index = j;
        
        if (found_match) {
          break;
        }
      }
      
      if (!found_match) {
        assign_index = last_time_index + 1;
      }
      
      out_indices.data[i] = assign_index;
    }
  }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  if (nlhs > 1) {
    mexErrMsgTxt("Too many outputs.");
    return;
  }
  
  if (nrhs == 0) {
    plhs[0] = mxCreateString(BFW_VERSION_ID);
    return;
  }
  
  if (nrhs < 2 || nrhs > 3) {
    mexErrMsgTxt("2 or 3 inputs required.");
    return;
  }
  
  bool check_is_sorted = true;
  
  const mxArray *time_array = prhs[0];
  const mxArray *events_array = prhs[1];
  
  if (nrhs == 3) {
    check_is_sorted = determine_to_check_is_sorted(prhs[2]);
  }
  
  check_inputs(time_array, events_array, check_is_sorted);
  
  auto c_time = decompose_double_array(time_array);
  auto c_events = decompose_double_array(events_array);
  
  mxArray *time_indices = mxCreateUninitNumericMatrix(c_events.size, 1, mxINT64_CLASS, mxREAL);
  
  if (!time_indices) {
    mexErrMsgTxt("Failed to create output array.");
  }
  
  plhs[0] = time_indices;
  
  auto c_indices = decompose_numeric_array<int64_t>(time_indices);
  
  if (c_indices.size > 0) {
    std::memset(c_indices.data, 0, c_indices.size * sizeof(int64_t));
  }
  
//   find_indices_binary(c_time, c_events, c_indices);
  find_indices(c_time, c_events, c_indices);
}