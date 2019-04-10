#include "rowops_nd.hpp"

namespace util {
int run_sum(const DecomposedArray<double> &input_data,
            const std::vector<SimpleDecomposedArray<uint64_t>> &indices,
            const int64_t index_start,
            const int64_t index_stop,
            const util::NDDimensionIndices &dimension_index_combinations,
            double *out_data_ptr) {

  uint64_t max_input_rows = input_data.descriptor.rows();
  int64_t n_combinations = dimension_index_combinations.input.size();

  for (int64_t i = index_start; i < index_stop; i++) {
    const auto &decomposed_indices = indices[i];

    for (int64_t j = 0; j < n_combinations; j++) {      
      double sum = 0.0;

      int64_t in_nd_index = dimension_index_combinations.input[j];
      int64_t assign_index = dimension_index_combinations.output[j] + i;

      for (int64_t k = 0; k < decomposed_indices.size; k++) {
        uint64_t in_row_index = decomposed_indices.data[k];

        if (in_row_index == 0 || in_row_index > max_input_rows) {
          //  Indices out of bounds.
          return FunctionResult::INDICES_OOB;
        }

        int64_t c_row_index = int64_t(in_row_index - 1);
        int64_t in_full_index = in_nd_index + c_row_index;

        sum += input_data.data[in_full_index];
      }

      out_data_ptr[assign_index] = sum;
    }
  }

  return 0;
}
  
//
int run_mean(const DecomposedArray<double> &input_data,
             const std::vector<SimpleDecomposedArray<uint64_t>> &indices,
             const int64_t index_start,
             const int64_t index_stop,
             const util::NDDimensionIndices &dimension_index_combinations,
             double *out_data_ptr) {

  uint64_t max_input_rows = input_data.descriptor.rows();
  int64_t n_combinations = dimension_index_combinations.input.size();

  for (int64_t i = index_start; i < index_stop; i++) {
    const auto &decomposed_indices = indices[i];

    double denominator = double(decomposed_indices.size);

    for (int64_t j = 0; j < n_combinations; j++) {      
      double sum_mean = 0.0;

      int64_t in_nd_index = dimension_index_combinations.input[j];
      int64_t assign_index = dimension_index_combinations.output[j] + i;

      for (int64_t k = 0; k < decomposed_indices.size; k++) {
        uint64_t in_row_index = decomposed_indices.data[k];

        if (in_row_index == 0 || in_row_index > max_input_rows) {
          //  Indices out of bounds.
          return FunctionResult::INDICES_OOB;
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

int run_nan_mean(const DecomposedArray<double> &input_data,
                 const std::vector<SimpleDecomposedArray<uint64_t>> &indices,
                 const int64_t index_start,
                 const int64_t index_stop,
                 const util::NDDimensionIndices &dimension_index_combinations,
                 double *out_data_ptr) {

  uint64_t max_input_rows = input_data.descriptor.rows();
  int64_t n_combinations = dimension_index_combinations.input.size();

  for (int64_t i = index_start; i < index_stop; i++) {
    const auto &decomposed_indices = indices[i];

    for (int64_t j = 0; j < n_combinations; j++) {      
      double sum_mean = 0.0;
      double denominator = double(decomposed_indices.size);

      int64_t in_nd_index = dimension_index_combinations.input[j];
      int64_t assign_index = dimension_index_combinations.output[j] + i;

      for (int64_t k = 0; k < decomposed_indices.size; k++) {
        uint64_t in_row_index = decomposed_indices.data[k];

        if (in_row_index == 0 || in_row_index > max_input_rows) {
          //  Indices out of bounds.
          return FunctionResult::INDICES_OOB;
        }

        int64_t c_row_index = int64_t(in_row_index - 1);
        int64_t in_full_index = in_nd_index + c_row_index;
        
        double value = input_data.data[in_full_index];
        
        if (std::isnan(value)) {
          denominator -= 1.0;
        } else {
          sum_mean += value;
        }
      }

      sum_mean /= denominator;

      out_data_ptr[assign_index] = sum_mean;
    }
  }

  return 0;
}

//  median
int run_median(const DecomposedArray<double> &input_data,
               const std::vector<SimpleDecomposedArray<uint64_t>> &indices,
               const int64_t index_start,
               const int64_t index_stop,
               const util::NDDimensionIndices &dimension_index_combinations,
               double *out_data_ptr) {

  uint64_t max_input_rows = input_data.descriptor.rows();
  int64_t n_combinations = dimension_index_combinations.input.size();
  
  std::vector<double> ordered_values;

  for (int64_t i = index_start; i < index_stop; i++) {
    const auto &decomposed_indices = indices[i];

    for (int64_t j = 0; j < n_combinations; j++) {      
      double sum_mean = 0.0;
      double denominator = double(decomposed_indices.size);

      int64_t in_nd_index = dimension_index_combinations.input[j];
      int64_t assign_index = dimension_index_combinations.output[j] + i;
      
      if (ordered_values.size() < decomposed_indices.size) {
        ordered_values.resize(decomposed_indices.size);
      }
      
      bool found_nan = false;

      for (int64_t k = 0; k < decomposed_indices.size; k++) {
        uint64_t in_row_index = decomposed_indices.data[k];

        if (in_row_index == 0 || in_row_index > max_input_rows) {
          //  Indices out of bounds.
          return FunctionResult::INDICES_OOB;
        }

        int64_t c_row_index = int64_t(in_row_index - 1);
        int64_t in_full_index = in_nd_index + c_row_index;
        
        double value = input_data.data[in_full_index];
        
        if (std::isnan(value)) {
          found_nan = true;
          break;
        } else {
          ordered_values[k] = value;
        }
      }

      if (found_nan || decomposed_indices.size == 0) {
        out_data_ptr[assign_index] = std::nan("");
        
      } else {
        auto begin_it = &ordered_values[0];
        auto end_it = begin_it + decomposed_indices.size;
        
        std::sort(begin_it, end_it);
        
        int64_t mid = decomposed_indices.size / static_cast<int64_t>(2);
        
        if (decomposed_indices.size % 2 != 0) {
          out_data_ptr[assign_index] = ordered_values[mid];
          
        } else {
          const double mid_value = ordered_values[mid];
          const double prev_value = ordered_values[mid-1];
          
          out_data_ptr[assign_index] = prev_value + (mid_value - prev_value) / 2.0;
        }
      }
    }
  }

  return 0;
}

//  nan_median
int run_nan_median(const DecomposedArray<double> &input_data,
                   const std::vector<SimpleDecomposedArray<uint64_t>> &indices,
                   const int64_t index_start,
                   const int64_t index_stop,
                   const util::NDDimensionIndices &dimension_index_combinations,
                   double *out_data_ptr) {

  uint64_t max_input_rows = input_data.descriptor.rows();
  int64_t n_combinations = dimension_index_combinations.input.size();
  
  std::vector<double> ordered_values;

  for (int64_t i = index_start; i < index_stop; i++) {
    const auto &decomposed_indices = indices[i];

    for (int64_t j = 0; j < n_combinations; j++) {      
      double sum_mean = 0.0;
      double denominator = double(decomposed_indices.size);

      int64_t in_nd_index = dimension_index_combinations.input[j];
      int64_t assign_index = dimension_index_combinations.output[j] + i;
      
      if (ordered_values.size() < decomposed_indices.size) {
        ordered_values.resize(decomposed_indices.size);
      }
      
      int64_t ordered_index = 0;

      for (int64_t k = 0; k < decomposed_indices.size; k++) {
        uint64_t in_row_index = decomposed_indices.data[k];

        if (in_row_index == 0 || in_row_index > max_input_rows) {
          //  Indices out of bounds.
          return FunctionResult::INDICES_OOB;
        }

        int64_t c_row_index = int64_t(in_row_index - 1);
        int64_t in_full_index = in_nd_index + c_row_index;
        
        double value = input_data.data[in_full_index];
        
        if (!std::isnan(value)) {
          ordered_values[ordered_index++] = value;
        }
      }

      if (ordered_index == 0) {
        out_data_ptr[assign_index] = std::nan("");
        
      } else {
        auto begin_it = &ordered_values[0];
        auto end_it = begin_it + ordered_index;
        
        std::sort(begin_it, end_it);
        
        int64_t mid = ordered_index / static_cast<int64_t>(2);
        
        if (ordered_index % 2 != 0) {
          out_data_ptr[assign_index] = ordered_values[mid];
          
        } else {
          const double mid_value = ordered_values[mid];
          const double prev_value = ordered_values[mid-1];
          
          out_data_ptr[assign_index] = prev_value + (mid_value - prev_value) / 2.0;
        }
      }
    }
  }

  return 0;
}

} //  namespace util

//  Maps function type specifier to function pointer.
static const util::function_map_t FUNC_MAP{
  {util::FunctionTypes::MEAN, &util::run_mean},
  {util::FunctionTypes::NAN_MEAN, &util::run_nan_mean},
  {util::FunctionTypes::SUM, &util::run_sum},
  {util::FunctionTypes::MEDIAN, &util::run_median},
  {util::FunctionTypes::NAN_MEDIAN, &util::run_nan_median}        
};

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  using namespace util;
  
  auto decomposed_inputs = check_inputs(nlhs, plhs, nrhs, prhs);
  
  if (decomposed_inputs.is_requesting_version) {
    plhs[0] = decomposed_inputs.version_array;
    return;
  }
  
  const auto thread_type = decomposed_inputs.thread_type;
  const auto &indices = decomposed_inputs.indices;
  const auto &input_data = decomposed_inputs.data;
  const auto &input_descriptor = input_data.descriptor;
  
  mxArray *output_array = make_output_array(indices.size(), input_descriptor);
  double *out_data_ptr = mxGetPr(output_array);
  
  ArrayDescriptor output_descriptor(output_array);
  
  auto dim_index_combs = get_dimension_index_combinations(input_descriptor, output_descriptor);
  
  const auto &func = FUNC_MAP.at(decomposed_inputs.function_type);
  
  int status = run(func, thread_type, input_data, indices, dim_index_combs, out_data_ptr);
  
  if (status != FunctionResult::SUCCESS) {
    mxDestroyArray(output_array);
    
    if (status == FunctionResult::INDICES_OOB) {
      mexErrMsgTxt("Indices are out of bounds.");
    }
    
    mexErrMsgTxt("Internal error: unhandled error code.");
  }
  
  plhs[0] = output_array;
}