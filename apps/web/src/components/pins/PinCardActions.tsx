import { CardActions } from '@mui/material';
import type { ContentRef, Pin } from '../../../types/index.ts';
import CommentForm from '../common/CommentForm.tsx';
import ShareButton from '../common/ShareButton.tsx';
import LikePinButton from './LikePinButton.tsx';

type Props = {
  pin: Pin;
  onCommentAdded: () => void;
};

const PinCardActions = ({ pin, onCommentAdded }: Props) => {
  const subject: ContentRef = { type: 'pin', id: pin.id };

  const collapsedAction = (
    <>
      <LikePinButton pin={pin} />
      <ShareButton title={pin.name} path={`/pins/${pin.id}`} />
    </>
  );

  return (
    <CardActions sx={{ p: 2 }}>
      <CommentForm
        subject={subject}
        onCommentAdded={onCommentAdded}
        collapsedAction={collapsedAction}
      />
    </CardActions>
  );
};

export default PinCardActions;
