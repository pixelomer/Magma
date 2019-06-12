#ifndef __MAGMA_MACROS_H
#define __MAGMA_MACROS_H

// Convenience macros
#define sqlite3_bind_text(stmt, index, text) sqlite3_bind_text(stmt, index, text, strlen(text), SQLITE_STATIC)

// Used to communicate with MGViewControllers
#define DatabaseDidRemoveSourceNotification @"com.pixelomer.magma/DatabaseDidRemoveSource"
#define DatabaseDidAddSourceNotification @"com.pixelomer.magma/DatabaseDidAddSource"
#define DatabaseDidLoadNotification @"com.pixelomer.magma/DatabaseDidLoad"
#define DatabaseDidEncounterAnError @"com.pixelomer.magma/DatabaseDidEncounterAnError"

// Unused
#define DatabaseFailedToLoadNotification @"com.pixelomer.magma/DatabaseFailedToLoad"

#endif