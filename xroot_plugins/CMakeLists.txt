# @project      The CERN Tape Archive (CTA)
# @copyright    Copyright © 2018-2022 CERN
# @license      This program is free software, distributed under the terms of the GNU General Public
#               Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING". You can
#               redistribute it and/or modify it under the terms of the GPL Version 3, or (at your
#               option) any later version.
#
#               This program is distributed in the hope that it will be useful, but WITHOUT ANY
#               WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#               PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#               In applying this licence, CERN does not waive the privileges and immunities
#               granted to it by virtue of its status as an Intergovernmental Organization or
#               submit itself to any jurisdiction.

cmake_minimum_required (VERSION 3.17)

find_package(xrootd REQUIRED)
find_package(Protobuf3 REQUIRED)

include_directories(${XROOTD_INCLUDE_DIR} ${XROOTD_PRIVATE_INCLUDE_DIR})
include_directories(${CMAKE_SOURCE_DIR}/tapeserver)

#
# XRootD SSI Protocol Buffer bindings
#
include_directories(${XRD_SSI_PB_DIR}/include ${XRD_SSI_PB_DIR}/eos_cta/include)

#
# Compiled protocol buffers
#
include_directories(${CMAKE_BINARY_DIR}/eos_cta ${PROTOBUF3_INCLUDE_DIRS})

#
# XRootD SSI plugin for CTA Frontend
#
add_library(XrdSsiCta MODULE XrdSsiCtaServiceProvider.cpp XrdSsiCtaRequestProc.cpp XrdSsiCtaRequestMessage.cpp
                             AdminCmdStream.cpp
                             ../cmdline/CtaAdminCmdParser.cpp
                             ../common/config/Config.cpp
                             ../frontend/common/FrontendService.cpp
                             ../frontend/common/WorkflowEvent.cpp
                             ../frontend/common/AdminCmd.cpp)
if(CTA_USE_PGSCHED)
  target_link_libraries(XrdSsiCta ${XROOTD_XRDSSI_LIB} XrdSsiLib ctascheduler ctacommon ctacatalogue)
else()
  target_link_libraries(XrdSsiCta ${XROOTD_XRDSSI_LIB} XrdSsiLib ctascheduler ctacommon ctaobjectstore ctacatalogue)
endif()

install(TARGETS XrdSsiCta DESTINATION usr/${CMAKE_INSTALL_LIBDIR})
install(FILES cta-frontend-xrootd.conf.example DESTINATION ${CMAKE_INSTALL_SYSCONFDIR}/cta)
install(FILES cta-frontend.logrotate DESTINATION /etc/logrotate.d RENAME cta-frontend)
install(FILES cta-frontend.sysconfig DESTINATION /etc/sysconfig RENAME cta-frontend)
install(FILES cta-frontend.service DESTINATION /etc/systemd/system)
