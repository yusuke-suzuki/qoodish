# Changelog

## [3.9.2](https://github.com/yusuke-suzuki/qoodish/compare/v3.9.1...v3.9.2) (2026-07-29)


### Code Refactoring

* drop the push_notifications table ([0f9ecbb](https://github.com/yusuke-suzuki/qoodish/commit/0f9ecbbc67ed78aac2a14195c381367c742a1dda))

## [3.9.1](https://github.com/yusuke-suzuki/qoodish/compare/v3.9.0...v3.9.1) (2026-07-28)


### Bug Fixes

* notify only once when a like is repeated ([2b720d8](https://github.com/yusuke-suzuki/qoodish/commit/2b720d876f46eb960095051b2da830d389b374f3))

## [3.9.0](https://github.com/yusuke-suzuki/qoodish/compare/v3.8.0...v3.9.0) (2026-07-28)


### Features

* notify the map author of a new chapter ([ac5cfdb](https://github.com/yusuke-suzuki/qoodish/commit/ac5cfdb67fb38e6009a974058b2591d2e3daa014))

## [3.8.0](https://github.com/yusuke-suzuki/qoodish/compare/v3.7.0...v3.8.0) (2026-07-28)


### Features

* rework web push preference storage ([1b41cab](https://github.com/yusuke-suzuki/qoodish/commit/1b41cab6b4abcd78b3ef6b9cbe3af98fbc915e15)), closes [#564](https://github.com/yusuke-suzuki/qoodish/issues/564)


### Bug Fixes

* stop notifying yourself of your own like ([2eb938c](https://github.com/yusuke-suzuki/qoodish/commit/2eb938c2b2eb1963fd072f19e3e046b80b69502f))

## [3.7.0](https://github.com/yusuke-suzuki/qoodish/compare/v3.6.0...v3.7.0) (2026-07-27)


### Features

* add the user_preferences model ([72d3612](https://github.com/yusuke-suzuki/qoodish/commit/72d36120e385288d56aff41ed8364ad61dc7787b))

## [3.6.0](https://github.com/yusuke-suzuki/qoodish/compare/v3.5.0...v3.6.0) (2026-07-26)


### Features

* list the chapters written from a map ([8a0c4db](https://github.com/yusuke-suzuki/qoodish/commit/8a0c4dbfa210d3652b026d837bd5d9ed09f787a7))


### Bug Fixes

* delete notifications with their notifiable ([87f8a1e](https://github.com/yusuke-suzuki/qoodish/commit/87f8a1e198e55687d27350069acd3ddf0a5b14a6))

## [3.5.0](https://github.com/yusuke-suzuki/qoodish/compare/v3.4.0...v3.5.0) (2026-07-24)


### Features

* give chapters their own GeoJSON map ([43a5bd2](https://github.com/yusuke-suzuki/qoodish/commit/43a5bd2faea8d516c058e92be704e169076b600d))

## [3.4.0](https://github.com/yusuke-suzuki/qoodish/compare/v3.3.0...v3.4.0) (2026-07-24)


### Features

* let chapters carry an explicit cover image ([0f44c88](https://github.com/yusuke-suzuki/qoodish/commit/0f44c8896fb6593d5d35f447e627962bdb5317c8))


### Bug Fixes

* align chapter image eager loading ([8717dee](https://github.com/yusuke-suzuki/qoodish/commit/8717deeea7bfab1eff40554b919e292674708e93))
* hide notifications left by retired features ([338d9bb](https://github.com/yusuke-suzuki/qoodish/commit/338d9bba930a07e1fddc682d9466f361d8d6bb00))

## [3.3.0](https://github.com/yusuke-suzuki/qoodish/compare/v3.2.0...v3.3.0) (2026-07-23)


### Features

* add chapter likes and per-user journals ([4d38e6c](https://github.com/yusuke-suzuki/qoodish/commit/4d38e6c34916250b4476b73a726dac4fe9aadcd2))

## [3.2.0](https://github.com/yusuke-suzuki/qoodish/compare/v3.1.0...v3.2.0) (2026-07-22)


### Features

* encrypt journey trajectory at rest ([d76f20e](https://github.com/yusuke-suzuki/qoodish/commit/d76f20e2344fe3c16073ca896c571d99858f5610))

## [3.1.0](https://github.com/yusuke-suzuki/qoodish/compare/v3.0.0...v3.1.0) (2026-07-20)


### Features

* add bookmarks list endpoints ([7776409](https://github.com/yusuke-suzuki/qoodish/commit/777640943884a529b43b7a12aaf029a6cb186d04))
* add journeys and chapters API ([927eabe](https://github.com/yusuke-suzuki/qoodish/commit/927eabe345e4e7905c69c90fc6ca88646e2a801d))
* add note to journey checkins ([21bdaf6](https://github.com/yusuke-suzuki/qoodish/commit/21bdaf6502a4892e305d5b99e6faafd690778a01))
* allow retroactive journey checkins ([bca2e94](https://github.com/yusuke-suzuki/qoodish/commit/bca2e94d880e49cbf022fdc2b58c39310b644867))
* attach images to journey checkins ([8e45699](https://github.com/yusuke-suzuki/qoodish/commit/8e45699265f475feecd7d5b57cad9ae2705cd9ab))
* enforce not null on checked_in_at ([aa22076](https://github.com/yusuke-suzuki/qoodish/commit/aa220762ede234846840e1b0c90f8b7555c786d1))


### Bug Fixes

* guard follows/invites drops with if_exists ([af993a9](https://github.com/yusuke-suzuki/qoodish/commit/af993a939c7024504701eef51f1ac9132c549091))
* include author biography in chapter payload ([354d251](https://github.com/yusuke-suzuki/qoodish/commit/354d251fbc1f3e824b977fb566354137a00ea171))

## [3.0.0](https://github.com/yusuke-suzuki/qoodish/compare/v2.0.1...v3.0.0) (2026-06-23)


### ⚠ BREAKING CHANGES

* drop follows and invites tables

### Miscellaneous Chores

* drop follows and invites tables ([09edb33](https://github.com/yusuke-suzuki/qoodish/commit/09edb3316d129b32e2d24d8eade90b4e05695aab))

## [2.0.1](https://github.com/yusuke-suzuki/qoodish/compare/v2.0.0...v2.0.1) (2026-06-22)


### Bug Fixes

* ignore dropped legacy image columns ([de73ebd](https://github.com/yusuke-suzuki/qoodish/commit/de73ebd048ae681e16b01b501af27c349e843446))

## [2.0.0](https://github.com/yusuke-suzuki/qoodish/compare/v1.6.1...v2.0.0) (2026-06-22)


### ⚠ BREAKING CHANGES

* map JSON renames owner to author and following to bookmarking, drops shared/invitable/postable, and adds bookmarkable. Endpoints /maps/:id/collaborators and /maps/:id/follow become /maps/:id/coauthors and /maps/:id/bookmark, and coauthor invitations replace the old invite flow.
* JSON responses no longer include thumbnail_url, thumbnail_url_400, thumbnail_url_800, or profile_image_url.

### Features

* add user search endpoint ([7df4603](https://github.com/yusuke-suzuki/qoodish/commit/7df460334b491735d6df3a3fe450e57ebf01c6a6))
* redesign map access permissions ([833320d](https://github.com/yusuke-suzuki/qoodish/commit/833320d6d86afa1612603f741c7f2c997e12ebdc))


### Code Refactoring

* remove GCS legacy paths ([c0431b1](https://github.com/yusuke-suzuki/qoodish/commit/c0431b1fca40cbcd72c2c2058fd3cb649af306fd)), closes [#539](https://github.com/yusuke-suzuki/qoodish/issues/539)

## [1.6.1](https://github.com/yusuke-suzuki/qoodish/compare/v1.6.0...v1.6.1) (2026-05-31)


### Bug Fixes

* read legacy columns directly in backfill ([d50be3e](https://github.com/yusuke-suzuki/qoodish/commit/d50be3ee3fc8feb3d2b4059a3ffc226807fc08ec))

## [1.6.0](https://github.com/yusuke-suzuki/qoodish/compare/v1.5.1...v1.6.0) (2026-05-31)


### Features

* integrate Cloudflare Images upload flow ([da524ae](https://github.com/yusuke-suzuki/qoodish/commit/da524ae5ffa7f5e488326ecb454abe20acf74d63))

## [1.5.1](https://github.com/yusuke-suzuki/qoodish/compare/v1.5.0...v1.5.1) (2026-03-07)


### Bug Fixes

* delete Identity Platform account on destroy ([7a1b066](https://github.com/yusuke-suzuki/qoodish/commit/7a1b066e1abd90a70cd459f6ce62543bbfb33954))
* delete Identity Platform account on destroy ([4adde10](https://github.com/yusuke-suzuki/qoodish/commit/4adde10afd60c75b40964229d28dafd0e87f6c30))
* use GitHub App token to trigger workflows ([f0bde22](https://github.com/yusuke-suzuki/qoodish/commit/f0bde2241e679e02978abfb2c47f23a597e53499))
* use GitHub App token to trigger workflows ([832d3ef](https://github.com/yusuke-suzuki/qoodish/commit/832d3efb1c09df9621229cb8954a4577fd832f25))
* use PR number as Cloud Run traffic tag ([9fbe8e5](https://github.com/yusuke-suzuki/qoodish/commit/9fbe8e556b44e2bc84ca40b61ecc8a262de1c308))

## [1.5.0](https://github.com/yusuke-suzuki/qoodish/compare/v1.4.2...v1.5.0) (2026-02-27)


### Features

* add CORS support for GitHub Codespaces ([470dc86](https://github.com/yusuke-suzuki/qoodish/commit/470dc8605584cd097c443d371f2c84c8532c6ddb))


### Bug Fixes

* allow localhost:5000 in dev CORS ([26f1bfd](https://github.com/yusuke-suzuki/qoodish/commit/26f1bfdb7a9529f4a0dc0059c4d5d82a53dc6bba))
* correct i18n keys in model validations ([bda774d](https://github.com/yusuke-suzuki/qoodish/commit/bda774d28754ccda62aa27b6f278bcfef92bf460))
* normalize branch name with slashes ([76166c4](https://github.com/yusuke-suzuki/qoodish/commit/76166c49ed6a9f98879dd69f1858416f14baccb9))
* prevent stack overflow in log formatter ([1249c7c](https://github.com/yusuke-suzuki/qoodish/commit/1249c7c7a19153be4649b461d375283941f755ab))
