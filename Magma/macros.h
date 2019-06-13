#ifndef __MAGMA_MACROS_H
#define __MAGMA_MACROS_H

// Convenience macros
#define sqlite3_bind_text(stmt, index, text) sqlite3_bind_text(stmt, index, text, strlen(text), SQLITE_STATIC)

// Used to communicate with MGViewControllers
#define DatabaseDidRemoveSource @"com.pixelomer.magma/DatabaseDidRemoveSource"
#define DatabaseDidAddSource @"com.pixelomer.magma/DatabaseDidAddSource"
#define DatabaseDidLoad @"com.pixelomer.magma/DatabaseDidLoad"
#define DatabaseDidEncounterAnError @"com.pixelomer.magma/DatabaseDidEncounterAnError"
#define SourceDidStartRefreshing @"com.pixelomer.magma/SourceDidStartRefreshing"
#define SourceDidStopRefreshing @"com.pixelomer.magma/SourceDidStopRefreshing"
#define DatabaseDidFinishRefreshingSources @"com.pixelomer.magma/DatabaseDidFinishRefreshingSources"

// Unused
#define DatabaseFailedToLoadNotification @"com.pixelomer.magma/DatabaseFailedToLoad"

#endif