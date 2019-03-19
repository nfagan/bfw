#pragma once

#include "mex.h"
#include "rowop_nd_version.hpp"
#include <cstdint>
#include <vector>
#include <functional>
#include <thread>
#include <cstring>
#include <algorithm>
#include <cmath>
#include <map>
#include <string>

namespace util {  
  enum class FunctionTypes {
    MEAN,
    NAN_MEAN,
    SUM
  };
  
  enum class ThreadTypes {
    AUTO,
    SINGLE_THREADED
  };
  
  namespace FunctionResult {
    static constexpr int SUCCESS = 0;
    static constexpr int INDICES_OOB = 1;
  }
  
  struct ArrayDescriptor {
    mxClassID class_id;
    mwSize n_dimensions;
    int64_t size;
    const mwSize *dimensions;
    
    ArrayDescriptor() = default;
    
    ArrayDescriptor(const mxArray *array) {
      class_id = mxGetClassID(array);
      n_dimensions = mxGetNumberOfDimensions(array);
      size = mxGetNumberOfElements(array);
      dimensions = mxGetDimensions(array);
    }
    
    ~ArrayDescriptor() = default;
    
    mwSize rows() const {
      return dimensions[0];
    }
    
    mwSize cols() const {
      return dimensions[1];
    }
    
    std::vector<int64_t> cumulative_dimension_product() const {      
      std::vector<int64_t> result;
      
      result.resize(n_dimensions);
      result[0] = (int64_t) dimensions[0];
      
      for (int64_t i = 1; i < n_dimensions; i++) {
        int64_t tmp_prod = (int64_t) dimensions[i];
        
        for (int64_t j = i-1; j >= 0; j--) {
          tmp_prod *= dimensions[j];
        }
        
        result[i] = tmp_prod;
      }
      
      return result;
    }
  };  
  
  template <typename T>
  struct DecomposedArray {
    T *data;
    ArrayDescriptor descriptor;
    
    DecomposedArray() = default;
    
    DecomposedArray(const mxArray *array) : descriptor(array) {
      data = (T*) mxGetData(array);
    }
    
    ~DecomposedArray() = default;
  };
  
  template <typename T>
  struct SimpleDecomposedArray {
    T *data;
    int64_t size;
    
    SimpleDecomposedArray() = default;
    
    SimpleDecomposedArray(const mxArray *array) {
      data = (T*) mxGetData(array);
      size = mxGetNumberOfElements(array);
    }
  };
  
  //  Start and stop indices into array of uint64_t row index subsets, for
  //  use by threads.
  struct DistributedIndices {
    std::vector<int64_t> starts;
    std::vector<int64_t> stops;
  };
  
  //  Indices of dimensions > 1 for input and output arrays.
  struct NDDimensionIndices {
    std::vector<int64_t> input;
    std::vector<int64_t> output;
  };
  
  //  Input schema for mex routine.
  struct DecomposedInputs {
    DecomposedArray<double> data;
    std::vector<SimpleDecomposedArray<uint64_t>> indices;
    FunctionTypes function_type;
    ThreadTypes thread_type;
    mxArray *version_array;
    bool is_requesting_version;
    
    DecomposedInputs() : 
      data(), 
      indices(), 
      function_type(FunctionTypes::MEAN),
      thread_type(ThreadTypes::AUTO),
      version_array(nullptr),
      is_requesting_version(false) {
      //
    }
    
    ~DecomposedInputs() = default;
  };
  
  using row_function_t = std::function<int(const DecomposedArray<double>&,
          const std::vector<SimpleDecomposedArray<uint64_t>>&,
          const int64_t,
          const int64_t,
          const util::NDDimensionIndices&,
          double*)>;
  
  using function_map_t = std::map<FunctionTypes, row_function_t>;
  
  mxArray* make_output_array(int64_t n_indices, const ArrayDescriptor &in_array_descriptor) {
    mwSize n_dims = in_array_descriptor.n_dimensions;
    mwSize *new_dims = new mwSize[n_dims];
    
    //  First dimension is the number of indices. Remaining dimensions are
    //  the same as those in the original input.
    new_dims[0] = (mwSize) n_indices;
    
    for (mwSize i = 1; i < n_dims; i++) {
      new_dims[i] = in_array_descriptor.dimensions[i];
    }
    
    mxArray *out_array = mxCreateUninitNumericArray(n_dims, new_dims, mxDOUBLE_CLASS, mxREAL);
    
    delete[] new_dims;
    
    return out_array;
  }
  
  ThreadTypes get_thread_type_with_trap(const mxArray *thread_type_array) {
    //  Allow [] for default.
    if (mxIsEmpty(thread_type_array)) {
      return ThreadTypes::AUTO;
    }
    
    if (mxGetClassID(thread_type_array) != mxUINT32_CLASS) {
      mexErrMsgTxt("Thread type flag must be uint32.");
    }

    SimpleDecomposedArray<uint32_t> thread_type(thread_type_array);

    if (thread_type.size != 1) {
      mexErrMsgTxt("Thread type flag must have one element.");
    }

    uint32_t thread_type_id = thread_type.data[0];

    switch (thread_type_id) {
      case 0:
        return ThreadTypes::AUTO;
      case 1:
        return ThreadTypes::SINGLE_THREADED;
      default:
        mexErrMsgTxt("Unrecognized thread type id.");
    }
    
    return ThreadTypes::AUTO;
  }
  
  FunctionTypes get_function_type_with_trap(const mxArray *function_type_array) {
    //  Allow [] for default.
    if (mxIsEmpty(function_type_array)) {
      return FunctionTypes::MEAN;
    }
    
    if (mxGetClassID(function_type_array) != mxUINT32_CLASS) {
      mexErrMsgTxt("Function type flag must be uint32.");
    }

    SimpleDecomposedArray<uint32_t> function_type(function_type_array);

    if (function_type.size != 1) {
      mexErrMsgTxt("Function type flag must have one element.");
    }

    uint32_t function_type_id = function_type.data[0];

    switch (function_type_id) {
      case 0:
        return FunctionTypes::MEAN;
      case 1:
        return FunctionTypes::NAN_MEAN;
      case 2:
        return FunctionTypes::SUM;
      default:
        mexErrMsgTxt("Unrecognized function type id.");
    }
    
    return FunctionTypes::MEAN;
  }
  
  mxArray* get_version_char_array() {
    return mxCreateString(BFW_VERSION_ID);
  }
  
  DecomposedInputs check_inputs(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    DecomposedInputs result;
    
    //  Getting version
    if (nrhs == 0) {
      result.is_requesting_version = true;
      result.version_array = get_version_char_array();
      return result;
    }
    
    if (nlhs > 1) {
      mexErrMsgTxt("Only 1 output allowed.");
    }
    
    if (nrhs < 2 || nrhs > 4) {
      mexErrMsgTxt("Expected 2, 3 or 4, inputs.");
    }
    
    const mxArray *data = prhs[0];
    const mxArray *indices = prhs[1];

    if (mxGetClassID(data) != mxDOUBLE_CLASS) {
      mexErrMsgTxt("Data must be double.");
    }
    
    if (mxIsComplex(data)) {
      mexErrMsgTxt("Data must be real.");
    }
    
    if (nrhs > 2) {      
      result.function_type = get_function_type_with_trap(prhs[2]);
    }
    
    if (nrhs > 3) {
      result.thread_type = get_thread_type_with_trap(prhs[3]);
    }
    
    result.data = DecomposedArray<double>(data);

    if (mxGetClassID(indices) != mxCELL_CLASS) {
      mexErrMsgTxt("Indices aggregate must be a cell array.");
    }
    
    int64_t n_cells = mxGetNumberOfElements(indices);
    
    for (int64_t i = 0; i < n_cells; i++) {
      const mxArray *index = mxGetCell(indices, i);
      
      if (mxGetClassID(index) != mxUINT64_CLASS) {
        mexErrMsgTxt("Indices must be uint64.");
      }
      
      SimpleDecomposedArray<uint64_t> result_index(index);
      
      result.indices.push_back(result_index);
    }
    
    return result;
  }
  
  DistributedIndices distribute_indices(const int64_t threads, const int64_t tasks) {
    DistributedIndices result;
    
    if (threads < 1 || tasks < threads) {
      result.starts.push_back(0);
      result.stops.push_back(tasks);
      
      return result;
    }
    
    int64_t n_divs = tasks / threads;
    int64_t offset = 0;
    
    for (int64_t i = 0; i < threads; i++) {
      result.starts.push_back(offset);
      result.stops.push_back(offset + n_divs);
      
      offset += n_divs;
    }
    
    result.stops[threads-1] = tasks;
    
    return result;
  }
  
  int64_t subscripts_to_linear_index_sans_rows(const std::vector<int64_t> &dim_prod,
                                               const std::vector<int64_t> &subs) {
    int64_t index = 0;
    int64_t n_dims = dim_prod.size();
    int64_t n_subs = subs.size();
    
    #if false
    if (n_dims != n_subs + 1) {
      std::cout << "Mismatching sizes" << std::endl;
      return 0;
    }
    #endif
    
    for (int64_t i = 0; i < n_subs; i++) {
      index += (subs[i] * dim_prod[i]);
    }
    
    return index;
  }
  
  //  Get all combinations of indices into dimensions beyond the first.
  //
  //  Conceptually equivalent to:
  //    for i = 0:n_rows-1
  //      for j = 0:n_cols-1
  //        indices.push(i + j * n_rows)
  //  
  //  But for columns, 3d-slices, 4-d slices, ... 
  NDDimensionIndices get_dimension_index_combinations(const ArrayDescriptor &input_descriptor,
                                                      const ArrayDescriptor &output_descriptor) {
    NDDimensionIndices result;
    
    const int64_t dim_offset = 1;
    
    const int64_t n_remaining_dimensions = input_descriptor.n_dimensions - dim_offset;
    int64_t n_combinations = 1;
    
    for (int64_t i = 0; i < n_remaining_dimensions; i++) {
      n_combinations *= (int64_t) input_descriptor.dimensions[i+dim_offset];
    }
    
    std::vector<int64_t> current_indices;
    current_indices.resize(n_remaining_dimensions);
    std::fill(current_indices.begin(), current_indices.end(), 0);
    
    auto input_dim_product = input_descriptor.cumulative_dimension_product();
    auto output_dim_product = output_descriptor.cumulative_dimension_product();
    
    result.input.resize(n_combinations);
    result.output.resize(n_combinations);
    
    for (int64_t i = 0; i < n_combinations; i++) {
      //  Make input index (except rows)
      //  Make output index (except rows)
      
      int64_t input_ind = subscripts_to_linear_index_sans_rows(input_dim_product, current_indices);
      int64_t output_ind = subscripts_to_linear_index_sans_rows(output_dim_product, current_indices);
      
      result.input[i] = input_ind;
      result.output[i] = output_ind;
      
      current_indices[n_remaining_dimensions-1]++;
      
      for (int64_t j = n_remaining_dimensions-1; j > 0; j--) {
        if (current_indices[j] >= input_descriptor.dimensions[j+dim_offset]) {
          current_indices[j] = 0;
          current_indices[j-1]++;
        }
      }
    }
    
    return result;
  }
  
  void run_threaded(const util::row_function_t &func,
                    const DecomposedArray<double> &input_data,
                    const std::vector<SimpleDecomposedArray<uint64_t>> &indices,
                    const util::NDDimensionIndices &dimension_index_combinations,
                    double *out_data_ptr,
                    const DistributedIndices &thread_indices,
                    std::vector<int> &thread_status,
                    const int64_t thread_index) {
    
    const int64_t start = thread_indices.starts[thread_index];
    const int64_t stop = thread_indices.stops[thread_index];
    
    int status = func(input_data, indices, start, stop, 
                      dimension_index_combinations, out_data_ptr);
    
    thread_status[thread_index] = status;
  }
  
  int run(const util::row_function_t &func,
          util::ThreadTypes thread_type,
          const DecomposedArray<double> &input_data,
          const std::vector<SimpleDecomposedArray<uint64_t>> &indices,
          const util::NDDimensionIndices &dimension_index_combinations,
          double *out_data_ptr) {
    
    const int64_t n_threads = (int64_t) std::thread::hardware_concurrency();
    const int64_t n_indices = indices.size();
    
    const bool thread_condition = n_threads > 0 && n_indices >= n_threads;
    const bool use_threads = thread_type != ThreadTypes::SINGLE_THREADED && thread_condition;
    
    if (use_threads) {      
      auto thread_indices = util::distribute_indices(n_threads, n_indices);
      
      std::vector<int> thread_status;
      std::vector<std::thread> threads;
      
      thread_status.resize(n_threads);
      std::fill(thread_status.begin(), thread_status.end(), 0);
      
      for (int64_t i = 0; i < n_threads; i++) {
        threads.emplace_back([&, i]() -> void {
          run_threaded(func, input_data, indices, dimension_index_combinations, 
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
      return func(input_data, indices, 0, n_indices,
                  dimension_index_combinations, out_data_ptr);
    }
  }
  
}