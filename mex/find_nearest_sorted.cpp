#include "mex.h"
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
  
  void check_inputs(const mxArray *time_array, const mxArray *events_array) {
    if (!mxIsDouble(time_array) || !mxIsDouble(events_array)) {
      mexErrMsgTxt("Time and event arrays must be double arrays.");
    }
    
    if (mxIsComplex(time_array) || mxIsComplex(events_array)) {
      mexErrMsgTxt("Time and event arrays must be real double arrays.");
    }
    
    check_sorted(time_array, "time");
    check_sorted(events_array, "events");
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
  
  void find_indices(DecomposedArray<double> time, 
                    DecomposedArray<double> events, 
                    DecomposedArray<int64_t> out_indices) {
    
    int64_t time_index = 0;
    int64_t last_time_index = 0;
    
    for (int64_t i = 0; i < events.size; i++) {
      double event_time = events.data[i];
      
      if (std::isnan(event_time)) {
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
          
          if (last_difference < current_difference) {
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
  
  if (nrhs != 2) {
    mexErrMsgTxt("2 inputs required.");
    return;
  }
  
  if (nlhs > 1) {
    mexErrMsgTxt("Too many outputs.");
    return;
  }
  
  const mxArray *time_array = prhs[0];
  const mxArray *events_array = prhs[1];
  
  check_inputs(time_array, events_array);
  
  auto c_time = decompose_double_array(time_array);
  auto c_events = decompose_double_array(events_array);
  
  mxArray *time_indices = mxCreateUninitNumericMatrix(c_events.size, 1, mxINT64_CLASS, mxREAL);
  
  if (!time_indices) {
    mexErrMsgTxt("Failed to create output array.");
  }
  
  plhs[0] = time_indices;
  
  auto c_indices = decompose_numeric_array<int64_t>(time_indices);
  std::memset(c_indices.data, 0, c_indices.size * sizeof(int64_t));
  
  find_indices(c_time, c_events, c_indices);  
}