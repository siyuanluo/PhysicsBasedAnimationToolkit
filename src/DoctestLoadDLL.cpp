#include "pba/DoctestLoadDLL.h"

/**
 * These compile definitions need to be declared only once.
 * See
 * https://github.com/doctest/doctest/blob/master/examples/executable_dll_and_plugin/implementation_2.cpp
 */
#define DOCTEST_CONFIG_IMPLEMENTATION_IN_DLL
#define DOCTEST_CONFIG_IMPLEMENT
#include <doctest/doctest.h>

namespace pba {

void force_load_dll()
{
    // no-op, just force linking binary to load this DLL
}

} // namespace pba