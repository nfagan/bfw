#include "mex.h"
#include "rowops_nd.hpp"
#include <cstring>
#include <algorithm>
#include <thread>

namespace util {  
  inline int run(const DecomposedArray<double> &input_data,
                 const mxArray *indices_array,
                 const int64_t index_start,
                 const int64_t index_stop,
                 const util::NDDimensionIndices &dimension_index_combinations,
                 double *out_data_ptr) {
    
    uint64_t max_input_rows = input_data.descriptor.rows();
    int64_t n_combinations = dimension_index_combinations.input.size();
  
    for (int64_t i = index_start; i < index_stop; i++) {
      const mxArray *index = mxGetCell(indices_array, i);

      if (mxGetClassID(index) != mxUINT64_CLASS) {
        //  Not an index.
        return 1;
      }

      DecomposedArray<uint64_t> decomposed_indices(index);
      double denominator = double(decomposed_indices.descriptor.size);

      for (int64_t j = 0; j < n_combinations; j++) {      
        double sum_mean = 0.0;

        int64_t in_nd_index = dimension_index_combinations.input[j];
        int64_t assign_index = dimension_index_combinations.output[j] + i;

        for (int64_t k = 0; k < decomposed_indices.descriptor.size; k++) {
          uint64_t in_row_index = decomposed_indices.data[k];

          if (in_row_index == 0 || in_row_index > max_input_rows) {
            //  Indices out of bounds.
            return 2;
          }

          int64_t c_row_index = int64_t(in_row_index - 1);
          int64_t in_full_index = in_nd_index + c_row_index;

          sum_mean += input_data.data[in_full_index];
        }

        sum_mean /= denominator;

        out_data_ptr[assign_index] = sum_mean;
      }
    }
    
    return 0;
  }
  
  void run_threaded(const DecomposedArray<double> &input_data,
                    const mxArray *indices_array,
                    const util::NDDimensionIndices &dimension_index_combinations,
                    double *out_data_ptr,
                    const DistributedIndices &thread_indices,
                    std::vector<int> &thread_status,
                    const int64_t thread_index) {
    
    const int64_t start = thread_indices.starts[thread_index];
    const int64_t stop = thread_indices.stops[thread_index];
    
    int status = util::run(input_data, indices_array, start, stop, dimension_index_combinations, out_data_ptr);
    
    thread_status[thread_index] = status;
  }
  
  inline int run(const DecomposedArray<double> &input_data,
                 const mxArray *indices_array,
                 const ArrayDescriptor &indices_descriptor,
                 const util::NDDimensionIndices &dimension_index_combinations,
                 double *out_data_ptr) {
    
    const int64_t n_threads = (int64_t) std::thread::hardware_concurrency();
    const int64_t n_indices = indices_descriptor.size;
    
    const bool use_threads = n_threads > 0 && n_indices >= n_threads;
    
    if (use_threads) {      
      auto thread_indices = util::distribute_indices(n_threads, n_indices);
      
      std::vector<int> thread_status;
      std::vector<std::thread> threads;
      
      thread_status.resize(n_threads);
      std::fill(thread_status.begin(), thread_status.end(), 0);
      
      for (int64_t i = 0; i < n_threads; i++) {
        threads.emplace_back([&, i]() -> void {
          run_threaded(input_data, indices_array, dimension_index_combinations, 
                       out_data_ptr, thread_indices, thread_status, i);
        });
      }
      
      for (auto &thr : threads) {
        thr.join();        
      }
      
      for (const auto &status : thread_status) {
        if (status != 0) {
          return status;
        }
      }
      
      return 0;
      
    } else {
      return run(input_data, indices_array, 0, indices_descriptor.size,
                 dimension_index_combinations, out_data_ptr);
    }
  }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  using namespace util;
  
  validate_intial_inputs(nlhs, plhs, nrhs, prhs);
  
  const mxArray *data_array = prhs[0];
  const mxArray *indices_array = prhs[1];
  
  DecomposedArray<double> input_data(data_array);
  ArrayDescriptor indices_descriptor(indices_array);
  
  mxArray *output_array = make_output_array(indices_descriptor.size, input_data.descriptor);
  ArrayDescriptor output_descriptor(output_array);
  double *out_data_ptr = mxGetPr(output_array);
  
  auto dim_index_combs = get_dimension_index_combinations(input_data.descriptor, output_descriptor);
  
  int status = run(input_data, indices_array, indices_descriptor, dim_index_combs, out_data_ptr);
  
  if (status != 0) {
    mxDestroyArray(output_array);
    
    if (status == 1) {
      mexErrMsgTxt("Indices arrays must be uint64.");
    }
    
    if (status == 2) {
      mexErrMsgTxt("Indices are out of bounds.");
    }
    
    mexErrMsgTxt("Unknown error.");
  }
  
  plhs[0] = output_array;
}