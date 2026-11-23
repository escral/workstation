// Ghostty draws a hollow block where the cursor is in unfocused windows and
// has no option to turn it off. This paints over the outline with whatever
// lies just outside it. Only the outer few pixels of the cell are touched,
// so the character under the cursor stays.
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);
    // Hidden cursors (full-screen TUIs) still report a rect; leave it alone.
    if (iFocus > 0 || iCursorVisible.x < 0.5) return;

    // xy is the left-top corner; y grows upward.
    vec2 lo = vec2(iCurrentCursor.x, iCurrentCursor.y - iCurrentCursor.w);
    vec2 hi = vec2(iCurrentCursor.x + iCurrentCursor.z, iCurrentCursor.y);
    if (any(lessThan(fragCoord, lo - 1.0)) || any(greaterThan(fragCoord, hi + 1.0))) return;

    float left = fragCoord.x - lo.x, right = hi.x - fragCoord.x;
    float bottom = fragCoord.y - lo.y, top = hi.y - fragCoord.y;
    float edge = min(min(left, right), min(bottom, top));
    if (edge > 3.0) return;

    float reach = edge + 3.0;
    vec2 off = edge == left ? vec2(-reach, 0.0)
             : edge == right ? vec2(reach, 0.0)
             : edge == bottom ? vec2(0.0, -reach)
             : vec2(0.0, reach);
    fragColor = texture(iChannel0, (fragCoord + off) / iResolution.xy);
}
