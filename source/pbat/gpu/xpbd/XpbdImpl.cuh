#ifndef PBAT_GPU_XPBD_XPBD_IMPL_CUH
#define PBAT_GPU_XPBD_XPBD_IMPL_CUH

#define EIGEN_NO_CUDA
#include "pbat/Aliases.h"
#undef EIGEN_NO_CUDA

#include "pbat/gpu/Aliases.h"
#include "pbat/gpu/common/Buffer.cuh"
#include "pbat/gpu/geometry/PrimitivesImpl.cuh"
#include "pbat/gpu/geometry/SweepAndPruneImpl.cuh"

#include <array>
#include <cstddef>
#include <thrust/host_vector.h>
#include <vector>

namespace pbat {
namespace gpu {
namespace xpbd {

class XpbdImpl
{
  public:
    enum EConstraint : int { StableNeoHookean = 0, Collision, NumberOfConstraintTypes };
    static auto constexpr kConstraintTypes = static_cast<int>(EConstraint::NumberOfConstraintTypes);

    /**
     * @brief
     * @param V
     * @param T
     */
    XpbdImpl(
        Eigen::Ref<GpuMatrixX const> const& X,
        Eigen::Ref<GpuIndexMatrixX const> const& V,
        Eigen::Ref<GpuIndexMatrixX const> const& F,
        Eigen::Ref<GpuIndexMatrixX const> const& T,
        std::size_t nMaxVertexTriangleOverlaps,
        GpuScalar kMaxCollisionPenetration = GpuScalar{1.});
    /**
     * @brief
     */
    void PrepareConstraints();
    /**
     * @brief
     * @param dt
     * @param iterations
     * @params substeps
     */
    void Step(GpuScalar dt, GpuIndex iterations, GpuIndex substeps);
    /**
     * @brief
     * @return
     */
    std::size_t NumberOfParticles() const;
    /**
     * @brief
     * @return
     */
    std::size_t NumberOfConstraints() const;
    /**
     * @brief
     * @param X
     */
    void SetPositions(Eigen::Ref<GpuMatrixX const> const& X);
    /**
     * @brief
     * @param v
     */
    void SetVelocities(Eigen::Ref<GpuMatrixX const> const& v);
    /**
     * @brief
     * @param f
     */
    void SetExternalForces(Eigen::Ref<GpuMatrixX const> const& f);
    /**
     * @brief
     * @param minv
     */
    void SetMassInverse(Eigen::Ref<GpuMatrixX const> const& minv);
    /**
     * @brief
     * @param l
     */
    void SetLameCoefficients(Eigen::Ref<GpuMatrixX const> const& l);
    /**
     * @brief
     * @param alpha
     * @param eConstraint
     */
    void SetCompliance(Eigen::Ref<GpuMatrixX const> const& alpha, EConstraint eConstraint);
    /**
     * @brief
     * @param partitions
     */
    void SetConstraintPartitions(std::vector<std::vector<GpuIndex>> const& partitions);
    /**
     * @brief
     * @param kMaxCollisionPenetration
     */
    void SetMaxCollisionPenetration(GpuScalar kMaxCollisionPenetration);
    /**
     * @brief
     * @param muS
     * @param muK
     */
    void SetFrictionCoefficients(GpuScalar muS, GpuScalar muK);
    /**
     * @brief
     * @return
     */
    common::Buffer<GpuScalar, 3> const& GetVelocity() const;
    /**
     * @brief
     * @return
     */
    common::Buffer<GpuScalar, 3> const& GetExternalForce() const;
    /**
     * @brief
     * @return
     */
    common::Buffer<GpuScalar> const& GetMassInverse() const;
    /**
     * @brief
     * @return
     */
    common::Buffer<GpuScalar> const& GetLameCoefficients() const;
    /**
     * @brief
     * @return
     */
    common::Buffer<GpuScalar> const& GetShapeMatrixInverse() const;
    /**
     * @brief
     * @return
     */
    common::Buffer<GpuScalar> const& GetRestStableGamma() const;
    /**
     * @brief
     * @param eConstraint
     * @return
     */
    common::Buffer<GpuScalar> const& GetLagrangeMultiplier(EConstraint eConstraint) const;
    /**
     * @brief
     * @param eConstraint
     * @return
     */
    common::Buffer<GpuScalar> const& GetCompliance(EConstraint eConstraint) const;
    /**
     * @brief
     * @return
     */
    std::vector<common::Buffer<GpuIndex>> const& GetPartitions() const;

    using OverlapType = typename geometry::SweepAndPruneImpl::OverlapType;
    /**
     * @brief Get the Vertex Triangle Overlap Candidates list
     *
     * @return thrust::host_vector<OverlapType>
     */
    thrust::host_vector<OverlapType> GetVertexTriangleOverlapCandidates() const;

  public:
    geometry::PointsImpl X;    ///< Vertex/particle positions
    geometry::SimplicesImpl V; ///< Vertex simplices
    geometry::SimplicesImpl F; ///< Triangle simplices
    geometry::SimplicesImpl T; ///< Tetrahedral simplices
  private:
    geometry::SweepAndPruneImpl SAP; ///< Sweep and prune broad phase

    common::Buffer<GpuScalar, 3> mPositions;      ///< Vertex/particle positions at time t
    common::Buffer<GpuScalar, 3> mVelocities;     ///< Vertex/particle velocities
    common::Buffer<GpuScalar, 3> mExternalForces; ///< Vertex/particle external forces
    common::Buffer<GpuScalar> mMassInverses;      ///< Vertex/particle mass inverses
    common::Buffer<GpuScalar> mLame;              ///< Lame coefficients
    common::Buffer<GpuScalar>
        mShapeMatrixInverses; ///< 3x3x|#elements| array of material shape matrix inverses
    common::Buffer<GpuScalar>
        mRestStableGamma; ///< 1. + mu/lambda, where mu,lambda are Lame coefficients
    std::array<common::Buffer<GpuScalar>, kConstraintTypes>
        mLagrangeMultipliers; ///< "Lagrange" multipliers:
                              ///< lambda[0] -> Stable Neo-Hookean constraint multipliers
                              ///< lambda[1] -> Collision penalty constraint multipliers
    std::array<common::Buffer<GpuScalar>, kConstraintTypes>
        mCompliance; ///< Compliance
                     ///< alpha[0] -> Stable Neo-Hookean constraint compliance
                     ///< alpha[1] -> Collision penalty constraint compliance

    std::vector<common::Buffer<GpuIndex>> mPartitions; ///< Constraint partitions
    GpuScalar mStaticFrictionCoefficient;              ///< Coulomb static friction coefficient
    GpuScalar mDynamicFrictionCoefficient;             ///< Coulomb dynamic friction coefficient
    GpuScalar mAverageEdgeLength;       ///< Average edge length of collision (triangle) mesh
    GpuScalar mMaxCollisionPenetration; ///< Coefficient controlling the maximum collision
                                        ///< constraint violation as max violation =
                                        ///< mMaxCollisionPenetration*mAverageEdgeLength. To
                                        ///< maintain stability, past this threshold, a collision
                                        ///< constraint will not perform any projection.
};

} // namespace xpbd
} // namespace gpu
} // namespace pbat

#endif // PBAT_GPU_XPBD_XPBD_IMPL_CUH